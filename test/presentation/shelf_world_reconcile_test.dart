import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Rect;

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

  ShelfWorld buildWorld(LevelDef level) {
    final GameSessionController controller = GameSessionController(
      level: level,
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
    'a completed triple removes the cleared product components',
    () => _TestGame(buildWorld(_clearLevel())),
    (_TestGame game) async {
      final ShelfWorld world = game.world;
      await _settle(game);
      // comp0 = [000, 000, _], comp1 = [000, _, _]  -> 3 products on screen.
      expect(world.children.whereType<ProductComponent>(), hasLength(3));

      // Placing the third sku_000 into comp0 completes the triple, which clears.
      world.controller.selectCell(CellAddress.fromCompartmentIndex(1, 0));
      world.controller.placeSelectedAt(CellAddress.fromCompartmentIndex(0, 2));
      await _settle(game);

      // The cleared products must be gone from the view, not left behind.
      expect(world.children.whereType<ProductComponent>(), isEmpty);
    },
  );

  testWithGame<_TestGame>(
    'dragging a product to complete a triple clears it (reported bug)',
    () => _TestGame(buildWorld(_clearLevel())),
    (_TestGame game) async {
      final ShelfWorld world = game.world;
      await _settle(game);
      expect(world.children.whereType<ProductComponent>(), hasLength(3));

      final BoardLayout layout = const BoardLayoutCalculator().calculate(
        Vector2(390, 844),
        hasLane: false,
        laneDefs: const <MovingLaneDef>[],
      );
      final CellAddress source = CellAddress.fromCompartmentIndex(1, 0);
      final CellAddress target = CellAddress.fromCompartmentIndex(0, 2);
      final Rect sourceRect = layout.cellRect(source);
      final Rect targetRect = layout.cellRect(target);
      final Vector2 targetPos = Vector2(
        targetRect.center.dx,
        targetRect.center.dy,
      );

      // Drive the real drag path: lift the lone sku_000 and drop it onto comp0,
      // completing 000/000/000.
      world.inputRouter.onProductDragStart(
        source,
        Vector2(sourceRect.center.dx, sourceRect.center.dy),
      );
      await _settle(game);
      world.inputRouter.onProductDragUpdate(targetPos);
      await _settle(game);
      world.inputRouter.onProductDragEnd(targetPos);
      // Real time so the deferred snap animation lands and commits the move.
      await _pump(game, dt: 0.05, steps: 16);

      expect(world.children.whereType<ProductComponent>(), isEmpty);
    },
  );

  testWithGame<_TestGame>(
    'draws exactly one component per visible product',
    () => _TestGame(buildWorld(_relocationLevel())),
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
    () => _TestGame(buildWorld(_relocationLevel())),
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

  testWithGame<_TestGame>(
    'isPresentationBusy is true while a move animates and clears when settled',
    () => _TestGame(buildWorld(_relocationLevel())),
    (_TestGame game) async {
      final ShelfWorld world = game.world;
      await _settle(game);
      expect(world.isPresentationBusy, isFalse, reason: 'at rest');

      world.controller.selectCell(CellAddress.fromCompartmentIndex(0, 0));
      world.controller.placeSelectedAt(CellAddress.fromCompartmentIndex(1, 1));
      await _settle(game);
      expect(world.isPresentationBusy, isTrue, reason: 'move animating');

      // Advance past the relocation tween (0.26s); it self-removes on finish.
      await _pump(game, dt: 0.05, steps: 10);
      expect(world.isPresentationBusy, isFalse, reason: 'settled');
    },
  );

  testWithGame<_TestGame>(
    'a hidden reveal arriving with a clear stays hidden until the pop settles',
    () => _TestGame(buildWorld(_revealLevel())),
    (_TestGame game) async {
      final ShelfWorld world = game.world;
      await _settle(game);
      // comp0 = [000, 000, _], comp1 = [000, _, _] -> 3 products.
      expect(world.children.whereType<ProductComponent>(), hasLength(3));

      // Complete the 000 triple in comp0; its hidden [001,002,003] layer reveals.
      world.controller.selectCell(CellAddress.fromCompartmentIndex(1, 0));
      world.controller.placeSelectedAt(CellAddress.fromCompartmentIndex(0, 2));
      await _settle(game);

      final List<ProductComponent> revealed = world.children
          .whereType<ProductComponent>()
          .toList();
      // The three hidden products exist, but are held invisible while the clear
      // pop plays out (Sprint C reveal-after-clear sequencing / P1.1).
      expect(revealed, hasLength(3));
      expect(revealed.every((ProductComponent c) => c.isRevealing), isTrue);
      expect(revealed.every((ProductComponent c) => c.opacity == 0), isTrue);
      expect(world.isPresentationBusy, isTrue, reason: 'pop + pending reveal');

      // After the pop (0.30s) + fade (0.22s) the reveal has fully settled in.
      await _pump(game, dt: 0.05, steps: 16);
      final List<ProductComponent> settled = world.children
          .whereType<ProductComponent>()
          .toList();
      final int boardCount = world.controller.state.board.visibleProductCount;
      // Sprint C contract: the reveal animation runs to completion (nothing is
      // left stuck invisible) and the revealed products fade fully in.
      expect(
        settled.where((ProductComponent c) => c.isRevealing),
        isEmpty,
        reason: 'no product stuck mid-reveal',
      );
      expect(
        settled.where((ProductComponent c) => c.opacity >= 1.0),
        isNotEmpty,
        reason: 'reveal faded in',
      );
      // The view holds exactly one component per board product (no duplicates).
      expect(settled, hasLength(boardCount));
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

Future<void> _pump(
  FlameGame game, {
  required double dt,
  required int steps,
}) async {
  for (var i = 0; i < steps; i += 1) {
    await Future<void>.delayed(Duration.zero);
    game.update(dt);
  }
}

LevelDef _clearLevel() {
  return LevelDef(
    id: 'level_reconcile_clear_test',
    levelNumber: 9,
    title: 'Reconcile Clear Test',
    seed: 9,
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

LevelDef _revealLevel() {
  return LevelDef(
    id: 'level_reconcile_reveal_test',
    levelNumber: 9,
    title: 'Reconcile Reveal Test',
    seed: 9,
    objective: ObjectiveRequirement(type: ObjectiveType.clearAll),
    compartments: <CompartmentDef>[
      CompartmentDef(
        index: 0,
        cells: const <String?>['sku_000', 'sku_000', null],
        hidden: const <String>['sku_001', 'sku_002', 'sku_003'],
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
