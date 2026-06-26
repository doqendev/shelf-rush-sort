import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/application/game_session/game_session_controller.dart';
import 'package:shelf_rush_sort/application/game_session/game_session_state.dart';
import 'package:shelf_rush_sort/domain/content/level_def.dart';
import 'package:shelf_rush_sort/domain/core/value_objects.dart';
import 'package:shelf_rush_sort/domain/game/fail_reason.dart';
import 'package:shelf_rush_sort/domain/game/move.dart';
import 'package:shelf_rush_sort/domain/game/objective.dart';
import 'package:shelf_rush_sort/domain/game/replay.dart';
import 'package:shelf_rush_sort/domain/moving_lanes/moving_lane_def.dart';
import 'package:shelf_rush_sort/infrastructure/analytics/analytics_service.dart';

void main() {
  test('revive resumes a failed timer level and emits analytics', () {
    final DebugAnalyticsService analytics = DebugAnalyticsService();
    final GameSessionController controller = GameSessionController(
      level: _timedLevel(),
      analytics: analytics,
    );

    controller.tick(const Duration(seconds: 2));
    expect(controller.state.status, GameSessionStatus.failed);

    controller.revive();

    expect(controller.state.status, GameSessionStatus.playing);
    expect(controller.state.board.levelEnded, isFalse);
    expect(
      analytics.events.map((event) => event.name),
      contains('level_revive'),
    );
  });

  test('lane grab and placement are recorded in replay log', () {
    final GameSessionController controller = GameSessionController(
      level: _laneReplayLevel(),
      analytics: DebugAnalyticsService(),
    );

    controller.grabLaneProduct('lane_main');
    controller.placeHeldLaneProduct(CellAddress.fromCompartmentIndex(0, 2));

    expect(
      controller.state.replay.commands.map((ReplayCommand command) {
        return command.type;
      }),
      <ReplayCommandType>[
        ReplayCommandType.grabLaneProduct,
        ReplayCommandType.placeHeldLaneProduct,
      ],
    );
    expect(controller.state.board.visibleProductCount, 0);
  });

  test('move limit is enforced by session end evaluator', () {
    final GameSessionController controller = GameSessionController(
      level: _moveLimitLevel(),
      analytics: DebugAnalyticsService(),
    );

    controller.selectCell(CellAddress.fromCompartmentIndex(1, 0));
    controller.placeSelectedAt(CellAddress.fromCompartmentIndex(0, 2));

    expect(controller.state.status, GameSessionStatus.failed);
    expect(controller.state.failReason, LevelFailReason.moveLimitExceeded);
  });

  test('move analytics includes move quality', () {
    final DebugAnalyticsService analytics = DebugAnalyticsService();
    final GameSessionController controller = GameSessionController(
      level: _moveQualityLevel(),
      analytics: analytics,
    );

    controller.selectCell(CellAddress.fromCompartmentIndex(1, 0));
    controller.placeSelectedAt(CellAddress.fromCompartmentIndex(0, 2));

    final moveEvent = analytics.events.firstWhere(
      (event) => event.name == 'move',
    );
    expect(
      moveEvent.parameters['move_quality'],
      MoveQuality.completesTriple.name,
    );
  });

  test('required finite lane miss fails with laneExhausted', () {
    final DebugAnalyticsService analytics = DebugAnalyticsService();
    final GameSessionController controller = GameSessionController(
      level: _requiredLaneLevel(),
      analytics: analytics,
    );

    controller.tick(const Duration(seconds: 1));

    expect(controller.state.status, GameSessionStatus.failed);
    expect(controller.state.failReason, LevelFailReason.laneExhausted);
    expect(
      controller.state.events.map((SessionEvent event) => event.type),
      contains(SessionEventType.laneMissed),
    );
    expect(analytics.events.map((event) => event.name), contains('lane_miss'));
  });

  test(
    'level-1 first move is restricted to the guided tutorial move (P0.5)',
    () {
      final GameSessionController controller = GameSessionController(
        level: _tutorialLevel(),
        analytics: DebugAnalyticsService(),
      );

      // A non-guided selection is rejected on the very first move.
      controller.selectCell(CellAddress.fromCompartmentIndex(1, 1));
      expect(controller.state.selectedCell, isNull);
      expect(controller.state.lastInvalidReason, isNotNull);

      // The guided move (1,0) -> (0,2) is allowed and completes a triple.
      controller.selectCell(CellAddress.fromCompartmentIndex(1, 0));
      expect(
        controller.state.selectedCell,
        CellAddress.fromCompartmentIndex(1, 0),
      );
      controller.placeSelectedAt(CellAddress.fromCompartmentIndex(0, 2));
      expect(controller.state.moveCount, 1);

      // After the first move, free play resumes.
      controller.selectCell(CellAddress.fromCompartmentIndex(1, 1));
      expect(
        controller.state.selectedCell,
        CellAddress.fromCompartmentIndex(1, 1),
      );
    },
  );

  test('paused controller does not advance the timer (P0.3)', () {
    final GameSessionController controller = GameSessionController(
      level: _pauseTestLevel(),
      analytics: DebugAnalyticsService(),
    );

    controller.tick(const Duration(seconds: 1));
    final Duration elapsedAtPause = controller.state.timer.elapsed;
    expect(controller.state.status, GameSessionStatus.playing);

    controller.setPaused(true);
    // Simulate five real seconds of engine ticks while the pause sheet is open.
    for (var i = 0; i < 50; i += 1) {
      controller.tick(const Duration(milliseconds: 100));
    }

    expect(controller.isPaused, isTrue);
    expect(controller.state.timer.elapsed, elapsedAtPause);
    expect(controller.state.status, GameSessionStatus.playing);

    controller.setPaused(false);
    controller.tick(const Duration(seconds: 1));
    expect(controller.state.timer.elapsed, greaterThan(elapsedAtPause));

    controller.dispose();
  });

  test(
    'cancelSelection clears selection so a cancelled drag cannot move (P1.1)',
    () {
      final GameSessionController controller = GameSessionController(
        level: _tutorialLevel(),
        analytics: DebugAnalyticsService(),
      );

      controller.selectCell(CellAddress.fromCompartmentIndex(1, 0));
      expect(controller.state.selectedCell, isNotNull);

      controller.cancelSelection();
      expect(controller.state.selectedCell, isNull);

      // With nothing selected, a later tap on an empty cell must not move.
      final int movesBefore = controller.state.moveCount;
      controller.placeSelectedAt(CellAddress.fromCompartmentIndex(0, 2));
      expect(controller.state.moveCount, movesBefore);

      controller.dispose();
    },
  );
}

LevelDef _moveLimitLevel() {
  return LevelDef(
    id: 'level_move_limit_test',
    levelNumber: 9,
    title: 'Move Limit Test',
    seed: 9,
    moveLimit: 1,
    objective: ObjectiveRequirement(type: ObjectiveType.clearAll),
    compartments: <CompartmentDef>[
      CompartmentDef(
        index: 0,
        cells: const <String?>['sku_000', 'sku_001', null],
      ),
      CompartmentDef(index: 1, cells: const <String?>['sku_002', null, null]),
      for (var index = 2; index < 15; index += 1)
        CompartmentDef(
          index: index,
          locked: true,
          cells: const <String?>[null, null, null],
        ),
    ],
  );
}

LevelDef _requiredLaneLevel() {
  return LevelDef(
    id: 'level_required_lane_test',
    levelNumber: 16,
    title: 'Required Lane Test',
    seed: 16,
    objective: ObjectiveRequirement(
      type: ObjectiveType.clearSkuTargets,
      targetCounts: <String, int>{'sku_000': 1},
    ),
    compartments: <CompartmentDef>[
      for (var index = 0; index < 15; index += 1)
        CompartmentDef(
          index: index,
          locked: true,
          cells: const <String?>[null, null, null],
        ),
    ],
    movingLanes: <MovingLaneDef>[
      MovingLaneDef(
        id: 'lane_required',
        orientation: LaneOrientation.horizontal,
        behavior: LaneBehavior.finite,
        speedCellsPerSecond: 1,
        requiredForObjective: true,
        queue: const <MovingLaneProductDef>[
          MovingLaneProductDef(skuId: 'sku_000', travelTimeMs: 1000),
        ],
      ),
    ],
  );
}

LevelDef _moveQualityLevel() {
  return LevelDef(
    id: 'level_move_quality_test',
    levelNumber: 10,
    title: 'Move Quality Test',
    seed: 10,
    objective: ObjectiveRequirement(type: ObjectiveType.clearAll),
    compartments: <CompartmentDef>[
      CompartmentDef(
        index: 0,
        cells: const <String?>['sku_000', 'sku_000', null],
      ),
      CompartmentDef(index: 1, cells: const <String?>['sku_000', null, null]),
      for (var index = 2; index < 15; index += 1)
        CompartmentDef(
          index: index,
          locked: true,
          cells: const <String?>[null, null, null],
        ),
    ],
  );
}

LevelDef _timedLevel() {
  return LevelDef(
    id: 'level_timer_test',
    levelNumber: 4,
    title: 'Timer Test',
    seed: 4,
    timeLimitSeconds: 1,
    objective: ObjectiveRequirement(type: ObjectiveType.clearAll),
    compartments: <CompartmentDef>[
      CompartmentDef(index: 0, cells: const <String?>['sku_000', null, null]),
      for (var index = 1; index < 15; index += 1)
        CompartmentDef(
          index: index,
          locked: true,
          cells: const <String?>[null, null, null],
        ),
    ],
  );
}

LevelDef _laneReplayLevel() {
  return LevelDef(
    id: 'level_lane_replay_test',
    levelNumber: 15,
    title: 'Lane Replay Test',
    seed: 15,
    objective: ObjectiveRequirement(type: ObjectiveType.clearAll),
    compartments: <CompartmentDef>[
      CompartmentDef(
        index: 0,
        cells: const <String?>['sku_000', 'sku_000', null],
      ),
      for (var index = 1; index < 15; index += 1)
        CompartmentDef(
          index: index,
          locked: true,
          cells: const <String?>[null, null, null],
        ),
    ],
    movingLanes: <MovingLaneDef>[
      MovingLaneDef(
        id: 'lane_main',
        orientation: LaneOrientation.horizontal,
        behavior: LaneBehavior.finite,
        speedCellsPerSecond: 1,
        queue: const <MovingLaneProductDef>[
          MovingLaneProductDef(skuId: 'sku_000', travelTimeMs: 5000),
        ],
      ),
    ],
  );
}

LevelDef _tutorialLevel() {
  return LevelDef(
    id: 'level_tutorial_test',
    levelNumber: 1,
    title: 'Tutorial Test',
    seed: 1,
    objective: ObjectiveRequirement(type: ObjectiveType.clearAll),
    compartments: <CompartmentDef>[
      CompartmentDef(
        index: 0,
        cells: const <String?>['sku_000', 'sku_000', null],
      ),
      CompartmentDef(
        index: 1,
        cells: const <String?>['sku_000', 'sku_001', null],
      ),
      for (var index = 2; index < 15; index += 1)
        CompartmentDef(
          index: index,
          locked: true,
          cells: const <String?>[null, null, null],
        ),
    ],
  );
}

LevelDef _pauseTestLevel() {
  return LevelDef(
    id: 'level_pause_test',
    levelNumber: 4,
    title: 'Pause Test',
    seed: 4,
    timeLimitSeconds: 60,
    objective: ObjectiveRequirement(type: ObjectiveType.clearAll),
    compartments: <CompartmentDef>[
      // A completable triple (3x sku_000) keeps the board playable — no jam,
      // no auto-clear — so the level stays in progress across ticks.
      CompartmentDef(
        index: 0,
        cells: const <String?>['sku_000', 'sku_000', null],
      ),
      CompartmentDef(index: 1, cells: const <String?>['sku_000', null, null]),
      for (var index = 2; index < 15; index += 1)
        CompartmentDef(
          index: index,
          locked: true,
          cells: const <String?>[null, null, null],
        ),
    ],
  );
}
