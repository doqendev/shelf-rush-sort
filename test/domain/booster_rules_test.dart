import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/domain/boosters/booster_def.dart';
import 'package:shelf_rush_sort/domain/boosters/booster_rules.dart';
import 'package:shelf_rush_sort/domain/content/level_def.dart';
import 'package:shelf_rush_sort/domain/core/value_objects.dart';
import 'package:shelf_rush_sort/domain/game/board_rules.dart';
import 'package:shelf_rush_sort/domain/game/board_state.dart';
import 'package:shelf_rush_sort/domain/game/objective.dart';
import 'package:shelf_rush_sort/domain/game/timer.dart';
import 'package:shelf_rush_sort/domain/moving_lanes/moving_lane_def.dart';
import 'package:shelf_rush_sort/domain/moving_lanes/moving_lane_state.dart';

void main() {
  group('BoosterRules', () {
    test('hint returns a concrete suggested move', () {
      final BoosterUseResult result = const BoosterRules().useBooster(
        _context(
          compartments: <CompartmentDef>[
            _compartment(0, <String?>['sku_a', 'sku_a', null]),
            _compartment(1, <String?>['sku_a', null, null]),
          ],
        ),
        BoosterKind.hint,
      );

      expect(result.used, isTrue);
      expect(result.suggestedMove, isNotNull);
      expect(result.reason, 'hint_selected');
    });

    test('hammer removes selected product and updates SKU objective', () {
      final BoosterUseResult result = const BoosterRules().useBooster(
        _context(
          objective: ObjectiveRequirement(
            type: ObjectiveType.clearSkuTargets,
            targetCounts: <String, int>{'sku_a': 1},
          ),
          selectedCell: CellAddress.fromCompartmentIndex(0, 0),
          compartments: <CompartmentDef>[
            _compartment(0, <String?>['sku_a', null, null]),
          ],
        ),
        BoosterKind.hammer,
      );

      expect(result.used, isTrue);
      expect(result.board.visibleProductCount, 0);
      expect(result.objective.remainingTargets['sku_a'], 0);
    });

    test('hammer rejects empty targets', () {
      final BoosterUseResult result = const BoosterRules().useBooster(
        _context(
          selectedCell: CellAddress.fromCompartmentIndex(0, 0),
          compartments: <CompartmentDef>[
            _compartment(0, <String?>[null, null, null]),
          ],
        ),
        BoosterKind.hammer,
      );

      expect(result.used, isFalse);
      expect(result.reason, 'hammer_empty_cell');
    });

    test('freeze time freezes timer elapsed', () {
      final BoosterUseResult result = const BoosterRules().useBooster(
        _context(timeLimitSeconds: 30),
        BoosterKind.freezeTime,
      );

      expect(result.used, isTrue);
      expect(result.timer.frozen, isTrue);
      expect(
        result.timer.tick(const Duration(seconds: 3)).elapsed,
        Duration.zero,
      );
    });

    test('extra shelf unlocks an empty locked support compartment', () {
      final BoosterUseResult result = const BoosterRules().useBooster(
        _context(),
        BoosterKind.extraShelf,
      );

      expect(result.used, isTrue);
      expect(result.board.compartmentAtIndex(1).locked, isFalse);
    });

    test('reveal hidden exposes hidden preview state', () {
      final BoosterUseResult result = const BoosterRules().useBooster(
        _context(
          compartments: <CompartmentDef>[
            CompartmentDef(
              index: 0,
              cells: const <String?>[null, null, null],
              hiddenLayers: <HiddenLayerDef>[
                HiddenLayerDef(
                  cells: const <String?>['sku_a', null, null],
                  previewMode: HiddenPreviewMode.hidden,
                ),
              ],
            ),
          ],
        ),
        BoosterKind.revealHidden,
      );

      expect(result.used, isTrue);
      expect(result.board.compartmentAtIndex(0).hiddenPreviewRevealed, isTrue);
    });

    test('slow conveyor applies lane speed state', () {
      final BoosterUseResult result = const BoosterRules().useBooster(
        _context(lanes: <MovingLaneState>[_lane()]),
        BoosterKind.slowConveyor,
      );

      expect(result.used, isTrue);
      expect(result.lanes.single.slowConveyorActive, isTrue);
      expect(result.lanes.single.speedMultiplier, lessThan(1));
    });

    test('shuffle preserves SKU counts and changes board hash', () {
      final BoosterContext context = _context(
        compartments: <CompartmentDef>[
          _compartment(0, <String?>['sku_a', 'sku_b', null]),
          _compartment(1, <String?>['sku_a', 'sku_c', null]),
          _compartment(2, <String?>['sku_b', 'sku_c', null]),
        ],
      );

      final BoosterUseResult result = const BoosterRules().useBooster(
        context,
        BoosterKind.shuffle,
      );

      expect(result.used, isTrue);
      expect(result.board.stableHash, isNot(context.board.stableHash));
      expect(_skuCounts(result.board), _skuCounts(context.board));
    });
  });
}

BoosterContext _context({
  ObjectiveRequirement? objective,
  List<CompartmentDef> compartments = const <CompartmentDef>[],
  List<MovingLaneState> lanes = const <MovingLaneState>[],
  CellAddress? selectedCell,
  int? timeLimitSeconds,
}) {
  final LevelDef level = LevelDef(
    id: 'level_booster_test',
    levelNumber: 12,
    title: 'Booster Test',
    seed: 12,
    timeLimitSeconds: timeLimitSeconds,
    objective: objective ?? ObjectiveRequirement(type: ObjectiveType.clearAll),
    compartments: <CompartmentDef>[
      for (var index = 0; index < compartmentCount; index += 1)
        compartments.firstWhere(
          (CompartmentDef compartment) => compartment.index == index,
          orElse: () => CompartmentDef(
            index: index,
            locked: index > 0,
            cells: const <String?>[null, null, null],
          ),
        ),
    ],
  );
  final BoardState board = const BoardRules()
      .resolveBoard(level.createBoardState())
      .state;
  const ObjectiveRules objectiveRules = ObjectiveRules();
  return BoosterContext(
    board: board,
    objective: objectiveRules.initialState(
      requirement: level.objective,
      board: board,
    ),
    timer: LevelTimer.fromSeconds(level.timeLimitSeconds),
    lanes: lanes,
    selectedCell: selectedCell,
    seed: level.seed,
    level: level,
  );
}

CompartmentDef _compartment(int index, List<String?> cells) {
  return CompartmentDef(index: index, cells: cells);
}

MovingLaneState _lane() {
  return MovingLaneState(
    def: MovingLaneDef(
      id: 'lane',
      orientation: LaneOrientation.horizontal,
      behavior: LaneBehavior.finite,
      speedCellsPerSecond: 1,
      queue: const <MovingLaneProductDef>[
        MovingLaneProductDef(skuId: 'sku_a', travelTimeMs: 1000),
      ],
    ),
  );
}

Map<String, int> _skuCounts(BoardState board) {
  final Map<String, int> counts = <String, int>{};
  for (final ProductInstance product in board.visibleProducts) {
    counts[product.skuId] = (counts[product.skuId] ?? 0) + 1;
  }
  return counts;
}
