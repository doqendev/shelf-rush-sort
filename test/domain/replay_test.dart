import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/domain/content/level_def.dart';
import 'package:shelf_rush_sort/domain/core/value_objects.dart';
import 'package:shelf_rush_sort/domain/game/move.dart';
import 'package:shelf_rush_sort/domain/game/objective.dart';
import 'package:shelf_rush_sort/domain/game/replay.dart';
import 'package:shelf_rush_sort/domain/moving_lanes/moving_lane_def.dart';

void main() {
  test('replay log round-trips JSON and plays back a shelf move', () {
    final LevelDef level = _level(
      compartments: <CompartmentDef>[
        _compartment(0, <String?>['sku_a', 'sku_a', null]),
        _compartment(1, <String?>['sku_a', null, null]),
      ],
    );
    final ReplayLog replay = ReplayLog(levelId: level.id, seed: level.seed)
        .append(
          ReplayCommand(
            type: ReplayCommandType.move,
            elapsedMs: 900,
            move: MoveAction(
              source: CellAddress.fromCompartmentIndex(1, 0),
              target: CellAddress.fromCompartmentIndex(0, 2),
            ),
          ),
        );

    final ReplayLog parsed = ReplayLog.fromJson(replay.toJson());
    final ReplayPlaybackResult result = const ReplayPlayer().play(
      level,
      parsed,
    );

    expect(parsed.commands.single.elapsedMs, 900);
    expect(result.passed, isTrue);
    expect(result.appliedCommands, 1);
    expect(result.board.visibleProductCount, 0);
  });

  test('replay player reconstructs moving-lane grab and placement', () {
    final LevelDef level = _level(
      compartments: <CompartmentDef>[
        _compartment(0, <String?>['sku_a', 'sku_a', null]),
      ],
      movingLanes: <MovingLaneDef>[
        MovingLaneDef(
          id: 'lane_main',
          orientation: LaneOrientation.horizontal,
          behavior: LaneBehavior.finite,
          speedCellsPerSecond: 1,
          queue: const <MovingLaneProductDef>[
            MovingLaneProductDef(skuId: 'sku_a', travelTimeMs: 5000),
          ],
        ),
      ],
    );
    final ReplayLog replay = ReplayLog(levelId: level.id, seed: level.seed)
        .append(
          const ReplayCommand(
            type: ReplayCommandType.grabLaneProduct,
            elapsedMs: 100,
            payload: <String, Object?>{'lane_id': 'lane_main'},
          ),
        )
        .append(
          ReplayCommand(
            type: ReplayCommandType.placeHeldLaneProduct,
            elapsedMs: 200,
            target: CellAddress.fromCompartmentIndex(0, 2),
          ),
        );

    final ReplayPlaybackResult result = const ReplayPlayer().play(
      level,
      ReplayLog.fromJson(replay.toJson()),
    );

    expect(result.passed, isTrue);
    expect(result.appliedCommands, 2);
    expect(result.board.visibleProductCount, 0);
    expect(result.lanes.single.heldProduct, isNull);
    expect(result.lanes.single.grabbedCount, 1);
  });

  test('replay player reports invalid command index', () {
    final LevelDef level = _level(
      compartments: <CompartmentDef>[
        _compartment(0, <String?>['sku_a', null, null]),
      ],
    );
    final ReplayLog replay = ReplayLog(levelId: level.id, seed: level.seed)
        .append(
          ReplayCommand(
            type: ReplayCommandType.move,
            elapsedMs: 100,
            move: MoveAction(
              source: CellAddress.fromCompartmentIndex(0, 1),
              target: CellAddress.fromCompartmentIndex(0, 2),
            ),
          ),
        );

    final ReplayPlaybackResult result = const ReplayPlayer().play(
      level,
      replay,
    );

    expect(result.passed, isFalse);
    expect(result.invalidCommandIndex, 0);
    expect(result.invalidReason, 'sourceEmpty');
  });
}

LevelDef _level({
  required List<CompartmentDef> compartments,
  List<MovingLaneDef> movingLanes = const <MovingLaneDef>[],
}) {
  return LevelDef(
    id: 'level_replay',
    levelNumber: 1,
    title: 'Replay Test',
    seed: 7,
    objective: ObjectiveRequirement(
      type: ObjectiveType.clearAll,
      targetCounts: <SkuId, int>{},
    ),
    compartments: <CompartmentDef>[
      for (var index = 0; index < compartmentCount; index += 1)
        compartments.firstWhere(
          (CompartmentDef compartment) => compartment.index == index,
          orElse: () => _lockedCompartment(index),
        ),
    ],
    movingLanes: movingLanes,
  );
}

CompartmentDef _compartment(int index, List<String?> cells) {
  return CompartmentDef(index: index, cells: cells);
}

CompartmentDef _lockedCompartment(int index) {
  return CompartmentDef(
    index: index,
    cells: const <String?>[null, null, null],
    locked: true,
  );
}
