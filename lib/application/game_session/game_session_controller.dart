import 'dart:async';

import '../../domain/boosters/booster_def.dart';
import '../../domain/boosters/booster_rules.dart';
import '../../domain/content/level_def.dart';
import '../../domain/core/value_objects.dart';
import '../../domain/game/board_rules.dart';
import '../../domain/game/board_state.dart';
import '../../domain/game/fail_reason.dart';
import '../../domain/game/level_end_evaluator.dart';
import '../../domain/game/move.dart';
import '../../domain/game/objective.dart';
import '../../domain/game/replay.dart';
import '../../domain/game/resolution.dart';
import '../../domain/game/timer.dart';
import '../../domain/moving_lanes/moving_lane_rules.dart';
import '../../domain/moving_lanes/moving_lane_state.dart';
import '../../infrastructure/analytics/analytics_event.dart';
import '../../infrastructure/analytics/analytics_service.dart';
import 'game_command.dart';
import 'game_session_state.dart';
import 'tutorial_controller.dart';

final class GameSessionController {
  GameSessionController({
    required LevelDef level,
    required this.analytics,
    BoardRules? boardRules,
    this.objectiveRules = const ObjectiveRules(),
    this.laneRules = const MovingLaneRules(),
    BoosterRules? boosterRules,
    this.levelEndEvaluator = const LevelEndEvaluator(),
    this.tutorialController = const TutorialController(),
    String? attemptId,
  }) : boardRules =
           boardRules ??
           BoardRules(
             allowSameCompartmentMoves: level.rules.allowSameCompartmentMoves,
           ),
       boosterRules =
           boosterRules ??
           BoosterRules(
             boardRules:
                 boardRules ??
                 BoardRules(
                   allowSameCompartmentMoves:
                       level.rules.allowSameCompartmentMoves,
                 ),
           ),
       _state = _createInitialState(
         level,
         objectiveRules,
         boardRules ??
             BoardRules(
               allowSameCompartmentMoves: level.rules.allowSameCompartmentMoves,
             ),
         attemptId ?? _newAttemptId(level),
       ) {
    unawaited(
      analytics.track(
        AnalyticsEvent(
          name: 'level_start',
          parameters: <String, Object?>{
            'level_id': level.id,
            'level_number': level.levelNumber,
            'seed': level.seed,
          },
        ),
      ),
    );
  }

  final AnalyticsService analytics;
  final BoardRules boardRules;
  final ObjectiveRules objectiveRules;
  final MovingLaneRules laneRules;
  final BoosterRules boosterRules;
  final LevelEndEvaluator levelEndEvaluator;
  final TutorialController tutorialController;
  final StreamController<GameSessionState> _states =
      StreamController<GameSessionState>.broadcast(sync: true);

  GameSessionState _state;
  bool _paused = false;

  /// Time since the player last interacted; after [_idleHintAfter] of
  /// inactivity an idle hint is surfaced so a stuck player recovers without the
  /// hint booster (hands-on v4 P1.3).
  Duration _idleSinceInteraction = Duration.zero;
  static const Duration _idleHintAfter = Duration(seconds: 5);

  GameSessionState get state => _state;

  Stream<GameSessionState> get states => _states.stream;

  /// Whether the deterministic simulation is paused. While paused, [tick] is a
  /// no-op, so the level timer and moving lanes do not advance.
  bool get isPaused => _paused;

  /// Pauses or resumes the simulation. The Flame engine should be paused and
  /// resumed alongside this (see the GameScreen pause flow) so rendering and
  /// simulation stay in lockstep.
  void setPaused(bool paused) {
    _paused = paused;
  }

  static GameSessionState _createInitialState(
    LevelDef level,
    ObjectiveRules objectiveRules,
    BoardRules boardRules,
    String attemptId,
  ) {
    final BoardState board = boardRules
        .resolveBoard(level.createBoardState())
        .state;
    return GameSessionState(
      level: level,
      board: board,
      objective: objectiveRules.initialState(
        requirement: level.objective,
        board: board,
      ),
      timer: LevelTimer.fromSeconds(level.timeLimitSeconds),
      replay: ReplayLog(levelId: level.id, seed: level.seed),
      lanes: level.movingLanes
          .map((lane) => MovingLaneState(def: lane))
          .toList(growable: false),
      attemptId: attemptId,
    );
  }

  static String _newAttemptId(LevelDef level) {
    return '${level.id}_${DateTime.now().toUtc().microsecondsSinceEpoch}';
  }

  void dispose() {
    unawaited(_states.close());
  }

  void dispatch(GameCommand command) {
    switch (command) {
      case SelectCellCommand():
        selectCell(command.address);
      case PlaceSelectedCommand():
        placeSelectedAt(command.target);
      case GrabLaneProductCommand():
        grabLaneProduct(command.laneId);
      case PlaceHeldLaneProductCommand():
        placeHeldLaneProduct(command.target);
      case UseBoosterCommand():
        useBooster(command.booster);
    }
  }

  void selectCell(CellAddress address) {
    if (_state.isEnded) {
      return;
    }
    _idleSinceInteraction = Duration.zero;
    final ProductInstance? product = _state.board.productAt(address);
    if (product == null) {
      if (!tutorialController.allowsPlacement(
        address,
        levelNumber: _state.level.levelNumber,
        moveCount: _state.moveCount,
      )) {
        _emitInvalid(InvalidMoveReason.restrictedByTutorial);
        return;
      }
      placeSelectedAt(address);
      return;
    }
    if (!tutorialController.allowsSelection(
      address,
      levelNumber: _state.level.levelNumber,
      moveCount: _state.moveCount,
    )) {
      _emitInvalid(InvalidMoveReason.restrictedByTutorial);
      return;
    }
    _emit(
      _state.copyWith(
        selectedCell: address,
        clearInvalidReason: true,
        events: <SessionEvent>[
          SessionEvent(
            type: SessionEventType.selectionChanged,
            payload: <String, Object?>{
              'address': address.key,
              'sku_id': product.skuId,
            },
          ),
        ],
      ),
    );
  }

  /// Clears the current selection without making a move — used when a drag is
  /// cancelled (released off-board) so a stale selection can't cause an
  /// accidental tap-to-place afterwards (second-pass audit P1.1).
  void cancelSelection() {
    if (_state.selectedCell == null) {
      return;
    }
    _emit(_state.copyWith(clearSelectedCell: true, clearInvalidReason: true));
  }

  void placeSelectedAt(CellAddress target) {
    if (_state.isEnded) {
      return;
    }
    _idleSinceInteraction = Duration.zero;
    final MovingLaneState? heldLane = _state.laneHoldingProduct;
    if (heldLane != null) {
      placeHeldLaneProduct(target);
      return;
    }
    final CellAddress? selected = _state.selectedCell;
    if (selected == null) {
      return;
    }
    if (!tutorialController.allowsPlacement(
      target,
      levelNumber: _state.level.levelNumber,
      moveCount: _state.moveCount,
    )) {
      _emitInvalid(InvalidMoveReason.restrictedByTutorial);
      return;
    }
    final MoveAction move = MoveAction(source: selected, target: target);
    final MoveQuality moveQuality = boardRules.classifyMove(_state.board, move);
    final ResolutionResult result = boardRules.applyMove(_state.board, move);
    unawaited(
      analytics.track(
        AnalyticsEvent(
          name: 'move',
          parameters: <String, Object?>{
            'level_id': _state.level.id,
            'source': selected.key,
            'target': target.key,
            'valid': result.isValid,
            'move_quality': moveQuality.name,
            if (result.invalidReason != null)
              'invalid_reason': result.invalidReason!.name,
          },
        ),
      ),
    );
    if (!result.isValid) {
      _emitInvalid(result.invalidReason!);
      return;
    }
    _applyResolution(
      result,
      replayCommand: ReplayCommand(
        type: ReplayCommandType.move,
        elapsedMs: _state.timer.elapsed.inMilliseconds,
        move: move,
      ),
    );
  }

  void grabLaneProduct(String laneId) {
    if (_state.isEnded) {
      return;
    }
    final int index = _state.lanes.indexWhere(
      (MovingLaneState lane) => lane.def.id == laneId,
    );
    if (index < 0) {
      return;
    }
    final GrabLaneProductResult result = laneRules.grabProduct(
      _state.lanes[index],
    );
    if (!result.isValid) {
      return;
    }
    final List<MovingLaneState> lanes = List<MovingLaneState>.of(_state.lanes);
    lanes[index] = result.state;
    final LaneHeldProduct heldProduct = result.state.heldProduct!;
    unawaited(
      analytics.track(
        AnalyticsEvent(
          name: 'lane_grab',
          parameters: <String, Object?>{
            'level_id': _state.level.id,
            'lane_id': laneId,
            'sku_id': heldProduct.product.skuId,
          },
        ),
      ),
    );
    _emit(
      _state.copyWith(
        lanes: lanes,
        replay: _state.replay.append(
          ReplayCommand(
            type: ReplayCommandType.grabLaneProduct,
            elapsedMs: _state.timer.elapsed.inMilliseconds,
            payload: <String, Object?>{'lane_id': laneId},
          ),
        ),
        clearSelectedCell: true,
        clearSuggestedMove: true,
        events: <SessionEvent>[
          SessionEvent(
            type: SessionEventType.laneGrabbed,
            payload: <String, Object?>{
              'lane_id': laneId,
              'sku_id': heldProduct.product.skuId,
            },
          ),
        ],
      ),
    );
  }

  void placeHeldLaneProduct(CellAddress target) {
    final int laneIndex = _state.lanes.indexWhere(
      (MovingLaneState lane) => lane.heldProduct != null,
    );
    if (laneIndex < 0) {
      return;
    }
    final LaneHeldProduct held = _state.lanes[laneIndex].heldProduct!;
    final ResolutionResult result = boardRules.placeProduct(
      _state.board,
      product: held.product,
      target: target,
    );
    if (!result.isValid) {
      _emitInvalid(result.invalidReason!);
      return;
    }
    final List<MovingLaneState> lanes = List<MovingLaneState>.of(_state.lanes);
    lanes[laneIndex] = laneRules.clearHeldProduct(lanes[laneIndex]);
    _applyResolution(
      result,
      lanes: lanes,
      laneDeliveredProduct: held.product,
      replayCommand: ReplayCommand(
        type: ReplayCommandType.placeHeldLaneProduct,
        elapsedMs: _state.timer.elapsed.inMilliseconds,
        target: target,
      ),
    );
  }

  /// Surfaces the best legal move as a hint once the player has been idle for
  /// [_idleHintAfter] without a selection or move (hands-on v4 P1.3). Input is
  /// never blocked — this only highlights, and it backs off once the player
  /// engages or a hint is already showing.
  void _maybeShowIdleHint(Duration delta) {
    if (_state.suggestedMove != null || _state.selectedCell != null) {
      _idleSinceInteraction = Duration.zero;
      return;
    }
    _idleSinceInteraction += delta;
    if (_idleSinceInteraction < _idleHintAfter) {
      return;
    }
    final LegalMove? hint = boardRules.bestHintMove(_state.board);
    if (hint != null) {
      _emit(_state.copyWith(suggestedMove: hint));
    }
    _idleSinceInteraction = Duration.zero;
  }

  void tick(Duration delta) {
    if (_paused || _state.isEnded) {
      return;
    }
    _maybeShowIdleHint(delta);
    if (_state.timer.limit == null && _state.lanes.isEmpty) {
      return;
    }
    final LevelTimer timer = _state.timer.tick(delta);
    final List<MovingLaneState> lanes = <MovingLaneState>[];
    final List<SessionEvent> events = <SessionEvent>[];
    for (var index = 0; index < _state.lanes.length; index += 1) {
      final MovingLaneState previous = _state.lanes[index];
      final MovingLaneState next = laneRules.tickLane(previous, delta);
      lanes.add(next);
      if (next.missedCount > previous.missedCount) {
        final String? missedSkuId = next.lastMissedSkuId;
        events.add(
          SessionEvent(
            type: SessionEventType.laneMissed,
            payload: <String, Object?>{
              'lane_id': next.def.id,
              'sku_id': ?missedSkuId,
              'missed_count': next.missedCount,
            },
          ),
        );
        unawaited(
          analytics.track(
            AnalyticsEvent(
              name: 'lane_miss',
              parameters: <String, Object?>{
                'level_id': _state.level.id,
                'lane_id': next.def.id,
                'sku_id': ?missedSkuId,
                'missed_count': next.missedCount,
              },
            ),
          ),
        );
      }
    }
    final LevelEnd? levelEnd = levelEndEvaluator.evaluate(
      board: _state.board,
      objective: _state.objective,
      timer: timer,
      lanes: lanes,
      level: _state.level,
      boardRules: boardRules,
      moveCount: _state.moveCount,
    );
    if (levelEnd?.isFail ?? false) {
      _fail(levelEnd!.failReason, timer: timer, lanes: lanes, events: events);
      return;
    }
    _emit(_state.copyWith(timer: timer, lanes: lanes, events: events));
  }

  BoosterContext _boosterContext() {
    return BoosterContext(
      board: _state.board,
      objective: _state.objective,
      timer: _state.timer,
      lanes: _state.lanes,
      selectedCell: _state.selectedCell,
      seed: _state.level.seed,
      level: _state.level,
    );
  }

  /// Whether [booster] would actually change something now, WITHOUT using it, so
  /// the UI never consumes inventory for a no-op (third-pass audit P0.1).
  BoosterAvailability canUseBooster(BoosterKind booster) {
    if (_state.isEnded) {
      return const BoosterAvailability.unavailable('level_ended');
    }
    return boosterRules.availability(_boosterContext(), booster);
  }

  void useBooster(BoosterKind booster) {
    if (_state.isEnded) {
      return;
    }
    final String preStateHash = _sessionHash(_state);
    final BoosterUseResult result = boosterRules.useBooster(
      _boosterContext(),
      booster,
    );
    final String postStateHash = _sessionHash(
      _state.copyWith(
        board: result.board,
        objective: result.objective,
        timer: result.timer,
        lanes: result.lanes,
        suggestedMove: result.suggestedMove,
      ),
    );
    unawaited(
      analytics.track(
        AnalyticsEvent(
          name: 'booster_use',
          parameters: <String, Object?>{
            'level_id': _state.level.id,
            'booster': booster.name,
            'used': result.used,
            'reason': result.reason,
            'pre_state_hash': preStateHash,
            'post_state_hash': postStateHash,
          },
        ),
      ),
    );
    _applyBoosterResult(booster, result);
  }

  void _applyBoosterResult(BoosterKind booster, BoosterUseResult result) {
    final List<SessionEvent> events = <SessionEvent>[
      SessionEvent(
        type: SessionEventType.boosterUsed,
        payload: <String, Object?>{
          'booster': booster.name,
          'used': result.used,
          'reason': result.reason,
          if (result.suggestedMove != null)
            'source': result.suggestedMove!.source.key,
          if (result.suggestedMove != null)
            'target': result.suggestedMove!.target.key,
        },
      ),
    ];
    final ResolutionResult? resolution = result.resolution;
    if (resolution != null) {
      for (final ClearedTriple triple in resolution.clearedTriples) {
        events.add(
          SessionEvent(
            type: SessionEventType.tripleCleared,
            payload: <String, Object?>{
              'sku_id': triple.skuId,
              'compartment': triple.compartmentIndex,
              'combo': resolution.comboCount,
            },
          ),
        );
      }
      if (resolution.revealedProducts.isNotEmpty) {
        events.add(
          SessionEvent(
            type: SessionEventType.hiddenRevealed,
            payload: <String, Object?>{
              'count': resolution.revealedProducts.length,
            },
          ),
        );
      }
    }
    var status = _state.status;
    var failReason = _state.failReason;
    final LevelEnd? levelEnd = levelEndEvaluator.evaluate(
      board: result.board,
      objective: result.objective,
      timer: result.timer,
      lanes: result.lanes,
      level: _state.level,
      boardRules: boardRules,
      moveCount: _state.moveCount,
    );
    if (levelEnd?.isWin ?? false) {
      status = GameSessionStatus.won;
      events.add(SessionEvent(type: SessionEventType.levelWon));
    } else if (levelEnd?.isFail ?? false) {
      status = GameSessionStatus.failed;
      failReason = levelEnd!.failReason;
      events.add(
        SessionEvent(
          type: SessionEventType.levelFailed,
          payload: <String, Object?>{'reason': failReason.name},
        ),
      );
    }
    _emit(
      _state.copyWith(
        board: result.board.copyWith(
          levelEnded: status != GameSessionStatus.playing,
        ),
        objective: result.objective,
        timer: result.timer,
        lanes: result.lanes,
        suggestedMove: result.suggestedMove,
        clearSuggestedMove: result.suggestedMove == null,
        status: status,
        failReason: failReason,
        clearInvalidReason: result.used,
        replay: result.used
            ? _state.replay.append(
                ReplayCommand(
                  type: ReplayCommandType.useBooster,
                  elapsedMs: _state.timer.elapsed.inMilliseconds,
                  payload: <String, Object?>{
                    'booster': booster.name,
                    ...result.replayPayload,
                  },
                ),
              )
            : _state.replay,
        events: events,
      ),
    );
  }

  /// Whether the current failure can be rescued by a rewarded revive.
  bool get canRevive {
    if (_state.status != GameSessionStatus.failed) {
      return false;
    }
    final LevelFailReason reason = _state.failReason;
    if (!canReviveFrom(reason)) {
      return false;
    }
    // Jam / no-useful / reserve failures are only revivable if a shuffle can
    // actually produce a playable board — never offer a revive that returns the
    // player to the same dead state (third-pass audit P0.3).
    if (reason == LevelFailReason.boardJammed ||
        reason == LevelFailReason.noUsefulMoves ||
        reason == LevelFailReason.reserveMismanaged) {
      final BoosterUseResult shuffle = boosterRules.useBooster(
        _boosterContext(),
        BoosterKind.shuffle,
      );
      return shuffle.used && boardRules.usefulMoves(shuffle.board).isNotEmpty;
    }
    return true;
  }

  /// Applies a rescue matched to the failure cause (second-pass audit P1.5):
  /// timer failures regain time, move-limit failures regain moves, and jammed /
  /// no-useful-move boards are reshuffled into a playable state. Failures with
  /// no meaningful rescue are not revived (and are never offered one).
  void revive({
    Duration rewind = const Duration(seconds: 30),
    int extraMoves = 5,
  }) {
    if (_state.status != GameSessionStatus.failed) {
      return;
    }
    final LevelFailReason reason = _state.failReason;
    if (!canReviveFrom(reason)) {
      return;
    }

    LevelTimer timer = _state.timer;
    BoardState board = _state.board;
    ObjectiveState objective = _state.objective;
    var moveCount = _state.moveCount;

    switch (reason) {
      case LevelFailReason.timerExpired:
        final Duration elapsed = _state.timer.elapsed - rewind;
        timer = _state.timer.copyWith(
          elapsed: elapsed.isNegative ? Duration.zero : elapsed,
        );
      case LevelFailReason.moveLimitExceeded:
        moveCount = (_state.moveCount - extraMoves).clamp(0, _state.moveCount);
      case LevelFailReason.boardJammed:
      case LevelFailReason.noUsefulMoves:
      case LevelFailReason.reserveMismanaged:
        final BoosterUseResult shuffle = boosterRules.useBooster(
          _boosterContext(),
          BoosterKind.shuffle,
        );
        if (!shuffle.used || boardRules.usefulMoves(shuffle.board).isEmpty) {
          // A revive that cannot produce a playable board is not honoured
          // (third-pass audit P0.3) — the player is not charged for a no-op.
          return;
        }
        board = shuffle.board;
        objective = shuffle.objective;
      case LevelFailReason.laneExhausted:
      case LevelFailReason.blockerRemaining:
      case LevelFailReason.objectiveImpossible:
      case LevelFailReason.none:
        return;
    }

    unawaited(
      analytics.track(
        AnalyticsEvent(
          name: 'level_revive',
          parameters: <String, Object?>{
            'level_id': _state.level.id,
            'level_number': _state.level.levelNumber,
            'fail_reason': reason.name,
            'moves': _state.moveCount,
          },
        ),
      ),
    );
    _emit(
      _state.copyWith(
        board: board.copyWith(levelEnded: false),
        timer: timer,
        objective: objective,
        moveCount: moveCount,
        status: GameSessionStatus.playing,
        failReason: LevelFailReason.none,
        clearInvalidReason: true,
        events: <SessionEvent>[SessionEvent(type: SessionEventType.revived)],
      ),
    );
  }

  void _applyResolution(
    ResolutionResult result, {
    List<MovingLaneState>? lanes,
    ProductInstance? laneDeliveredProduct,
    ReplayCommand? replayCommand,
  }) {
    ObjectiveState objective = _state.objective;
    if (laneDeliveredProduct != null) {
      objective = objectiveRules.onLaneDelivered(
        objective,
        product: laneDeliveredProduct,
      );
    }
    objective = objectiveRules.onResolution(objective, result);
    var status = _state.status;
    var failReason = _state.failReason;
    final int nextMoveCount = _state.moveCount + (result.moveApplied ? 1 : 0);
    final List<SessionEvent> events = <SessionEvent>[
      SessionEvent(type: SessionEventType.moveApplied),
    ];

    for (final ClearedTriple triple in result.clearedTriples) {
      events.add(
        SessionEvent(
          type: SessionEventType.tripleCleared,
          payload: <String, Object?>{
            'sku_id': triple.skuId,
            'compartment': triple.compartmentIndex,
            'combo': result.comboCount,
          },
        ),
      );
      unawaited(
        analytics.track(
          AnalyticsEvent(
            name: 'triple_clear',
            parameters: <String, Object?>{
              'level_id': _state.level.id,
              'sku_id': triple.skuId,
              'combo': result.comboCount,
            },
          ),
        ),
      );
    }
    if (result.revealedProducts.isNotEmpty) {
      events.add(
        SessionEvent(
          type: SessionEventType.hiddenRevealed,
          payload: <String, Object?>{'count': result.revealedProducts.length},
        ),
      );
    }

    final LevelEnd? levelEnd = levelEndEvaluator.evaluate(
      board: result.state,
      objective: objective,
      timer: _state.timer,
      lanes: lanes ?? _state.lanes,
      level: _state.level,
      boardRules: boardRules,
      moveCount: nextMoveCount,
    );

    if (levelEnd?.isWin ?? false) {
      status = GameSessionStatus.won;
      events.add(SessionEvent(type: SessionEventType.levelWon));
      unawaited(
        analytics.track(
          AnalyticsEvent(
            name: 'level_win',
            parameters: <String, Object?>{
              'level_id': _state.level.id,
              'duration_sec': _state.timer.elapsed.inSeconds,
              'moves': nextMoveCount,
            },
          ),
        ),
      );
    } else if (levelEnd?.isFail ?? false) {
      status = GameSessionStatus.failed;
      failReason = levelEnd!.failReason;
      events.add(
        SessionEvent(
          type: SessionEventType.levelFailed,
          payload: <String, Object?>{'reason': failReason.name},
        ),
      );
    }

    _emit(
      _state.copyWith(
        board: result.state.copyWith(
          levelEnded: status != GameSessionStatus.playing,
        ),
        objective: objective,
        lanes: lanes,
        status: status,
        failReason: failReason,
        clearSelectedCell: true,
        clearSuggestedMove: true,
        clearInvalidReason: true,
        moveCount: nextMoveCount,
        replay: replayCommand == null
            ? _state.replay
            : _state.replay.append(replayCommand),
        events: events,
      ),
    );
  }

  void _emitInvalid(InvalidMoveReason reason) {
    unawaited(
      analytics.track(
        AnalyticsEvent(
          name: 'invalid_move',
          parameters: <String, Object?>{
            'level_id': _state.level.id,
            'reason': reason.name,
          },
        ),
      ),
    );
    _emit(
      _state.copyWith(
        lastInvalidReason: reason,
        events: <SessionEvent>[
          SessionEvent(
            type: SessionEventType.invalidMove,
            payload: <String, Object?>{'reason': reason.name},
          ),
        ],
      ),
    );
  }

  void _fail(
    LevelFailReason reason, {
    LevelTimer? timer,
    List<MovingLaneState>? lanes,
    List<SessionEvent> events = const <SessionEvent>[],
  }) {
    unawaited(
      analytics.track(
        AnalyticsEvent(
          name: 'level_fail',
          parameters: <String, Object?>{
            'level_id': _state.level.id,
            'fail_reason': reason.name,
            'moves': _state.moveCount,
          },
        ),
      ),
    );
    _emit(
      _state.copyWith(
        board: _state.board.copyWith(levelEnded: true),
        timer: timer,
        lanes: lanes,
        status: GameSessionStatus.failed,
        failReason: reason,
        events: <SessionEvent>[
          ...events,
          SessionEvent(
            type: SessionEventType.levelFailed,
            payload: <String, Object?>{'reason': reason.name},
          ),
        ],
      ),
    );
  }

  void _emit(GameSessionState state) {
    _state = state;
    if (!_states.isClosed) {
      _states.add(_state);
    }
  }

  String _sessionHash(GameSessionState state) {
    return <Object?>[
      state.board.stableHash,
      state.timer.elapsed.inMilliseconds,
      state.timer.frozenRemaining.inMilliseconds,
      for (final MovingLaneState lane in state.lanes) lane.stableHash,
      state.suggestedMove?.source.key,
      state.suggestedMove?.target.key,
    ].join('#');
  }
}
