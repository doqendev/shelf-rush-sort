import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../application/game_session/game_session_controller.dart';
import '../../domain/content/product_def.dart';
import 'board/board_layout_calculator.dart';
import 'shelf_world.dart';

final class ShelfRushGame extends FlameGame<ShelfWorld> {
  factory ShelfRushGame({
    required GameSessionController controller,
    required ProductCatalog productCatalog,
  }) {
    final BoardLayout layout = const BoardLayoutCalculator().calculate(
      Vector2(390, 844),
      hasLane: controller.state.lanes.isNotEmpty,
    );
    final ShelfWorld world = ShelfWorld(
      controller: controller,
      productCatalog: productCatalog,
      initialLayout: layout,
    );
    return ShelfRushGame._(
      controller: controller,
      productCatalog: productCatalog,
      shelfWorld: world,
    );
  }

  ShelfRushGame._({
    required this.controller,
    required this.productCatalog,
    required ShelfWorld shelfWorld,
  }) : _shelfWorld = shelfWorld,
       super(world: shelfWorld);

  final GameSessionController controller;
  final ProductCatalog productCatalog;
  final ShelfWorld _shelfWorld;
  double _tickAccumulator = 0;

  @override
  Color backgroundColor() => const Color(0xFFF7F3E8);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();
    _shelfWorld.resize(size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();
    _shelfWorld.resize(size);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _tickAccumulator += dt;
    if (_tickAccumulator >= 0.1) {
      controller.tick(
        Duration(milliseconds: (_tickAccumulator * 1000).round()),
      );
      _tickAccumulator = 0;
    }
  }
}
