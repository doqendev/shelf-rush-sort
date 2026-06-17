import 'dart:async';

import '../../domain/boosters/booster_def.dart';
import '../../domain/boosters/booster_rules.dart';
import '../../domain/content/level_def.dart';
import '../../domain/core/value_objects.dart';
import '../../domain/game/board_rules.dart';
import '../../domain/game/board_state.dart';
import '../../domain/game/fail_reason.dart';
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
    this.boardRules = const BoardRules(),
    this.objectiveRules = const ObjectiveRules(),
    this.laneRules = const MovingLaneRules(),
    this.boosterRules = const BoosterRules(),
    this.tutorialController = const TutorialController(),
  }) : _state = _createInitialState(level, objectiveRules) {
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
  final TutorialController tutorialController;
  final StreamController<GameSessionState> _states =
      StreamController<GameSessionState>.broadcast(sync: true);

  GameSessionState _state;

  GameSessionState get state => _state;

  Stream<GameSessionState> get states => _states.stream;

  static GameSessionState _createInitialState(
    LevelDef level,
    ObjectiveRules objectiveRules,
  ) {
    final BoardRules boardRules = const BoardRules();
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
    );
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

  void placeSelectedAt(CellAddress target) {
    if (_state.isEnded) {
      return;
    }
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
      replayCommand: ReplayCommand(
        type: ReplayCommandType.placeHeldLaneProduct,
        elapsedMs: _state.timer.elapsed.inMilliseconds,
        target: target,
      ),
    );
  }

  void tick(Duration delta) {
    if (_state.isEnded) {
      return;
    }
    if (_state.timer.limit == null && _state.lanes.isEmpty) {
      return;
    }
    final LevelTimer timer = _state.timer.tick(delta);
    final List<MovingLaneState> lanes = _state.lanes
        .map((MovingLaneState lane) => laneRules.tickLane(lane, delta))
        .toList(growable: false);
    if (timer.expired) {
      _fail(LevelFailReason.timerExpired, timer: timer, lanes: lanes);
      return;
    }
    _emit(
      _state.copyWith(timer: timer, lanes: lanes, events: <SessionEvent>[]),
    );
  }

  void useBooster(BoosterKind booster) {
    if (_state.isEnded) {
      return;
    }
    final BoosterUseResult result = boosterRules.useBooster(
      _state.board,
      booster,
    );
    unawaited(
      analytics.track(
        AnalyticsEvent(
          name: 'booster_use',
          parameters: <String, Object?>{
            'level_id': _state.level.id,
            'booster': booster.name,
            'used': result.used,
            if (result.message != null) 'message': result.message,
          },
        ),
      ),
    );
    _emit(
      _state.copyWith(
        replay: result.used
            ? _state.replay.append(
                ReplayCommand(
                  type: ReplayCommandType.useBooster,
                  elapsedMs: _state.timer.elapsed.inMilliseconds,
                  payload: <String, Object?>{'booster': booster.name},
                ),
              )
            : _state.replay,
        events: <SessionEvent>[
          SessionEvent(
            type: SessionEventType.boosterUsed,
            payload: <String, Object?>{
              'booster': booster.name,
              'used': result.used,
              if (result.message != null) 'message': result.message,
            },
          ),
        ],
      ),
    );
  }

  void revive({Duration rewind = const Duration(seconds: 30)}) {
    if (_state.status != GameSessionStatus.failed) {
      return;
    }
    final Duration elapsed = _state.timer.elapsed - rewind;
    final LevelTimer timer = _state.timer.copyWith(
      elapsed: elapsed.isNegative ? Duration.zero : elapsed,
    );
    unawaited(
      analytics.track(
        AnalyticsEvent(
          name: 'level_revive',
          parameters: <String, Object?>{
            'level_id': _state.level.id,
            'level_number': _state.level.levelNumber,
            'fail_reason': _state.failReason.name,
            'moves': _state.moveCount,
          },
        ),
      ),
    );
    _emit(
      _state.copyWith(
        board: _state.board.copyWith(levelEnded: false),
        timer: timer,
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
    ReplayCommand? replayCommand,
  }) {
    final ObjectiveState objective = objectiveRules.onResolution(
      _state.objective,
      result,
    );
    var status = _state.status;
    var failReason = _state.failReason;
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

    if (objective.isComplete(result.state)) {
      status = GameSessionStatus.won;
      events.add(SessionEvent(type: SessionEventType.levelWon));
      unawaited(
        analytics.track(
          AnalyticsEvent(
            name: 'level_win',
            parameters: <String, Object?>{
              'level_id': _state.level.id,
              'duration_sec': _state.timer.elapsed.inSeconds,
              'moves': _state.moveCount + 1,
            },
          ),
        ),
      );
    } else {
      final LevelEnd? levelEnd = boardRules.evaluateLevelEnd(result.state);
      if (levelEnd?.isFail ?? false) {
        status = GameSessionStatus.failed;
        failReason = levelEnd!.failReason;
        events.add(
          SessionEvent(
            type: SessionEventType.levelFailed,
            payload: <String, Object?>{'reason': failReason.name},
          ),
        );
      }
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
        clearInvalidReason: true,
        moveCount: _state.moveCount + (result.moveApplied ? 1 : 0),
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
}
