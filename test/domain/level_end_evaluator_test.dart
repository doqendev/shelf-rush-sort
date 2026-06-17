import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/domain/content/level_def.dart';
import 'package:shelf_rush_sort/domain/core/value_objects.dart';
import 'package:shelf_rush_sort/domain/game/board_rules.dart';
import 'package:shelf_rush_sort/domain/game/fail_reason.dart';
import 'package:shelf_rush_sort/domain/game/level_end_evaluator.dart';
import 'package:shelf_rush_sort/domain/game/objective.dart';
import 'package:shelf_rush_sort/domain/game/timer.dart';
import 'package:shelf_rush_sort/domain/moving_lanes/moving_lane_state.dart';

void main() {
  test('legal but non-progressing boards fail as noUsefulMoves', () {
    final LevelDef level = _level(<CompartmentDef>[
      _compartment(0, <String?>['sku_a', 'sku_b', null]),
      _compartment(1, <String?>['sku_c', 'sku_d', null]),
    ]);
    const BoardRules rules = BoardRules();
    final board = rules.resolveBoard(level.createBoardState()).state;
    const ObjectiveRules objectiveRules = ObjectiveRules();

    final end = const LevelEndEvaluator().evaluate(
      board: board,
      objective: objectiveRules.initialState(
        requirement: level.objective,
        board: board,
      ),
      timer: LevelTimer.fromSeconds(null),
      lanes: const <MovingLaneState>[],
      level: level,
      boardRules: rules,
      moveCount: 0,
    );

    expect(end?.failReason, LevelFailReason.noUsefulMoves);
  });
}

LevelDef _level(List<CompartmentDef> compartments) {
  return LevelDef(
    id: 'level_end_test',
    levelNumber: 9,
    title: 'End Test',
    seed: 9,
    objective: ObjectiveRequirement(type: ObjectiveType.clearAll),
    compartments: <CompartmentDef>[
      for (var index = 0; index < compartmentCount; index += 1)
        compartments.firstWhere(
          (CompartmentDef compartment) => compartment.index == index,
          orElse: () => CompartmentDef(
            index: index,
            locked: true,
            cells: const <String?>[null, null, null],
          ),
        ),
    ],
  );
}

CompartmentDef _compartment(int index, List<String?> cells) {
  return CompartmentDef(index: index, cells: cells);
}
