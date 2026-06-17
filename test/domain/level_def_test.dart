import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/domain/blockers/blocker_def.dart';
import 'package:shelf_rush_sort/domain/content/level_def.dart';
import 'package:shelf_rush_sort/domain/core/value_objects.dart';
import 'package:shelf_rush_sort/domain/game/objective.dart';

void main() {
  test(
    'level definition carries blockers and hidden previews into board state',
    () {
      final LevelDef level = LevelDef(
        id: 'level_hidden_blocker_test',
        levelNumber: 12,
        title: 'Hidden Blocker Test',
        seed: 12,
        objective: ObjectiveRequirement(type: ObjectiveType.clearAll),
        compartments: <CompartmentDef>[
          CompartmentDef(
            index: 0,
            cells: const <String?>['sku_a', null, 'sku_b'],
            cellBlockers: const <BlockerKind>[
              BlockerKind.cover,
              BlockerKind.none,
              BlockerKind.none,
            ],
            productBlockers: const <BlockerKind>[
              BlockerKind.none,
              BlockerKind.none,
              BlockerKind.mysteryBag,
            ],
            hiddenLayers: <HiddenLayerDef>[
              HiddenLayerDef(
                cells: const <String?>['sku_c', null, 'sku_c'],
                previewMode: HiddenPreviewMode.silhouette,
              ),
            ],
          ),
          for (var index = 1; index < compartmentCount; index += 1)
            CompartmentDef(
              index: index,
              locked: true,
              cells: const <String?>[null, null, null],
            ),
        ],
      );

      final compartment = level.createBoardState().compartmentAtIndex(0);

      expect(compartment.cellAt(0).blocker, BlockerKind.cover);
      expect(compartment.cellAt(2).product!.blocker, BlockerKind.mysteryBag);
      expect(compartment.hiddenPreviewMode, HiddenPreviewMode.silhouette);
      expect(compartment.hiddenPreviewCells, const <String?>[
        'sku_c',
        null,
        'sku_c',
      ]);
      expect(compartment.hiddenStack.map((product) => product.skuId), <String>[
        'sku_c',
        'sku_c',
      ]);
    },
  );
}
