import 'dart:convert';
import 'dart:io';

import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/application/game_session/game_session_controller.dart';
import 'package:shelf_rush_sort/domain/content/level_def.dart';
import 'package:shelf_rush_sort/domain/content/product_def.dart';
import 'package:shelf_rush_sort/domain/core/value_objects.dart';
import 'package:shelf_rush_sort/domain/game/objective.dart';
import 'package:shelf_rush_sort/domain/moving_lanes/moving_lane_def.dart';
import 'package:shelf_rush_sort/infrastructure/analytics/analytics_service.dart';
import 'package:shelf_rush_sort/presentation/flame/board/board_layout_calculator.dart';
import 'package:shelf_rush_sort/presentation/flame/board/product_component.dart';
import 'package:shelf_rush_sort/presentation/flame/shelf_world.dart';

/// Covers the M2 retained-component reconciliation in [ShelfWorld]: products are
/// drawn exactly once, and a moved product keeps its component (animating to the
/// new slot) instead of being destroyed and recreated. This is the automated
/// render-loop test the second-pass audit said was missing.
late ProductCatalog _catalog;

void main() {
  setUpAll(() async {
    _catalog = ProductCatalog.fromJson(
      jsonDecode(
            await File(
              'assets/data/bundled/product_catalog.json',
            ).readAsString(),
          )
          as Map<String, Object?>,
    );
  });

  ShelfWorld buildWorld() {
    final GameSessionController controller = GameSessionController(
      level: _relocationLevel(),
      analytics: DebugAnalyticsService(),
    );
    return ShelfWorld(
      controller: controller,
      productCatalog: _catalog,
      initialLayout: const BoardLayoutCalculator().calculate(
        Vector2(390, 844),
        hasLane: false,
        laneDefs: const <MovingLaneDef>[],
      ),
    );
  }

  testWithGame<_TestGame>(
    'draws exactly one component per visible product',
    () => _TestGame(buildWorld()),
    (_TestGame game) async {
      await _settle(game);
      final List<ProductComponent> products = game.world.children
          .whereType<ProductComponent>()
          .toList();
      expect(products, hasLength(2));
      expect(
        products.map((ProductComponent c) => c.address).toSet(),
        <CellAddress>{
          CellAddress.fromCompartmentIndex(0, 0),
          CellAddress.fromCompartmentIndex(1, 0),
        },
      );
    },
  );

  testWithGame<_TestGame>(
    'a moved product keeps its component and animates to the new slot',
    () => _TestGame(buildWorld()),
    (_TestGame game) async {
      final ShelfWorld world = game.world;
      await _settle(game);
      final CellAddress source = CellAddress.fromCompartmentIndex(0, 0);
      final CellAddress target = CellAddress.fromCompartmentIndex(1, 1);
      final ProductComponent before = world.children
          .whereType<ProductComponent>()
          .firstWhere((ProductComponent c) => c.address == source);

      world.controller.selectCell(source);
      world.controller.placeSelectedAt(target);
      await _settle(game);

      final List<ProductComponent> products = world.children
          .whereType<ProductComponent>()
          .toList();
      // No duplicate or leaked components after the move.
      expect(products, hasLength(2));
      final ProductComponent after = products.firstWhere(
        (ProductComponent c) => c.address == target,
      );
      // The SAME component instance was re-homed, not destroyed + recreated.
      expect(identical(before, after), isTrue);
      // The relocation is animated, not an instant teleport.
      expect(after.children.whereType<MoveToEffect>(), isNotEmpty);
    },
  );
}

final class _TestGame extends FlameGame<ShelfWorld> {
  _TestGame(ShelfWorld world) : super(world: world);
}

Future<void> _settle(FlameGame game) async {
  for (var i = 0; i < 6; i += 1) {
    await Future<void>.delayed(Duration.zero);
    game.update(0);
  }
}

LevelDef _relocationLevel() {
  return LevelDef(
    id: 'level_reconcile_test',
    levelNumber: 9,
    title: 'Reconcile Test',
    seed: 9,
    objective: ObjectiveRequirement(type: ObjectiveType.clearAll),
    compartments: <CompartmentDef>[
      CompartmentDef(index: 0, cells: const <String?>['sku_000', null, null]),
      CompartmentDef(index: 1, cells: const <String?>['sku_001', null, null]),
      for (var index = 2; index < 15; index += 1)
        CompartmentDef(
          index: index,
          locked: true,
          cells: const <String?>[null, null, null],
        ),
    ],
  );
}
