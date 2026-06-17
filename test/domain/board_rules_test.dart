import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/domain/blockers/blocker_def.dart';
import 'package:shelf_rush_sort/domain/core/value_objects.dart';
import 'package:shelf_rush_sort/domain/game/board_rules.dart';
import 'package:shelf_rush_sort/domain/game/board_state.dart';
import 'package:shelf_rush_sort/domain/game/move.dart';

void main() {
  group('BoardRules', () {
    test('moves a product into an empty cell and clears an exact triple', () {
      final BoardState board = _boardWithFirstTwoCompartments(
        first: <String?>['sku_a', 'sku_a', null],
        second: <String?>['sku_a', null, null],
      );
      const BoardRules rules = BoardRules();
      final result = rules.applyMove(
        board,
        const MoveAction(
          source: CellAddress(row: 0, column: 1, cell: 0),
          target: CellAddress(row: 0, column: 0, cell: 2),
        ),
      );

      expect(result.isValid, isTrue);
      expect(result.clearedTriples, hasLength(1));
      expect(
        result.state.compartmentAtIndex(0).frontCells,
        everyElement(
          predicate<ShelfCell>((ShelfCell cell) => cell.product == null),
        ),
      );
    });

    test('reports targetOccupied for occupied target cells', () {
      final BoardState board = _boardWithFirstTwoCompartments(
        first: <String?>['sku_a', 'sku_b', null],
        second: <String?>['sku_a', null, null],
      );
      const BoardRules rules = BoardRules();
      final result = rules.applyMove(
        board,
        const MoveAction(
          source: CellAddress(row: 0, column: 1, cell: 0),
          target: CellAddress(row: 0, column: 0, cell: 1),
        ),
      );

      expect(result.invalidReason, InvalidMoveReason.targetOccupied);
    });

    test('moving a mystery bag reveals product identity', () {
      const CellAddress source = CellAddress(row: 0, column: 0, cell: 0);
      const CellAddress target = CellAddress(row: 0, column: 1, cell: 0);
      final BoardState board = BoardState(
        levelId: 'mystery_test',
        compartments: <CompartmentState>[
          CompartmentState(
            index: 0,
            frontCells: const <ShelfCell>[
              ShelfCell(
                product: ProductInstance(
                  id: 'p_1',
                  skuId: 'sku_a',
                  blocker: BlockerKind.mysteryBag,
                ),
              ),
              ShelfCell.empty(),
              ShelfCell.empty(),
            ],
          ),
          CompartmentState(
            index: 1,
            frontCells: const <ShelfCell>[
              ShelfCell.empty(),
              ShelfCell.empty(),
              ShelfCell.empty(),
            ],
          ),
          for (var index = 2; index < compartmentCount; index += 1)
            CompartmentState(
              index: index,
              locked: true,
              frontCells: const <ShelfCell>[
                ShelfCell.empty(),
                ShelfCell.empty(),
                ShelfCell.empty(),
              ],
            ),
        ],
      );

      final result = const BoardRules().applyMove(
        board,
        const MoveAction(source: source, target: target),
      );

      expect(result.isValid, isTrue);
      expect(result.state.cellAt(target)!.product!.blocker, BlockerKind.none);
    });
  });
}

BoardState _boardWithFirstTwoCompartments({
  required List<String?> first,
  required List<String?> second,
}) {
  var counter = 0;
  ProductInstance? product(String? skuId) {
    if (skuId == null) {
      return null;
    }
    counter += 1;
    return ProductInstance(id: 'p_$counter', skuId: skuId);
  }

  List<ShelfCell> cells(List<String?> skus) {
    return skus
        .map((String? skuId) {
          final ProductInstance? instance = product(skuId);
          return instance == null
              ? const ShelfCell.empty()
              : ShelfCell(product: instance);
        })
        .toList(growable: false);
  }

  return BoardState(
    levelId: 'test',
    compartments: <CompartmentState>[
      CompartmentState(index: 0, frontCells: cells(first)),
      CompartmentState(index: 1, frontCells: cells(second)),
      for (var index = 2; index < compartmentCount; index += 1)
        CompartmentState(
          index: index,
          locked: true,
          frontCells: const <ShelfCell>[
            ShelfCell.empty(),
            ShelfCell.empty(),
            ShelfCell.empty(),
          ],
        ),
    ],
  );
}
