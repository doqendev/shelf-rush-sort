import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/application/game_session/game_session_controller.dart';
import 'package:shelf_rush_sort/application/game_session/game_session_state.dart';
import 'package:shelf_rush_sort/domain/content/level_def.dart';
import 'package:shelf_rush_sort/domain/core/value_objects.dart';
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

  test('tutorial guides only the first level-one move', () {
    final GameSessionController controller = GameSessionController(
      level: _tutorialLevel(),
      analytics: DebugAnalyticsService(),
    );

    controller.selectCell(CellAddress.fromCompartmentIndex(1, 1));
    expect(
      controller.state.lastInvalidReason,
      InvalidMoveReason.restrictedByTutorial,
    );

    controller.selectCell(CellAddress.fromCompartmentIndex(1, 0));
    controller.placeSelectedAt(CellAddress.fromCompartmentIndex(1, 2));
    expect(
      controller.state.lastInvalidReason,
      InvalidMoveReason.restrictedByTutorial,
    );
    expect(controller.state.moveCount, 0);

    controller.selectCell(CellAddress.fromCompartmentIndex(1, 0));
    controller.placeSelectedAt(CellAddress.fromCompartmentIndex(0, 2));
    expect(controller.state.moveCount, 1);
    expect(controller.state.lastInvalidReason, isNull);

    controller.selectCell(CellAddress.fromCompartmentIndex(1, 1));
    expect(
      controller.state.selectedCell,
      CellAddress.fromCompartmentIndex(1, 1),
    );
  });
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
