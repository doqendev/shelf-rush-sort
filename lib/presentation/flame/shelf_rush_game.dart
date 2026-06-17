import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../application/game_session/game_session_controller.dart';
import '../../domain/content/product_def.dart';
import '../../infrastructure/platform/audio_service.dart';
import '../../infrastructure/platform/haptics_service.dart';
import 'board/board_layout_calculator.dart';
import 'shelf_world.dart';

final class ShelfRushGame extends FlameGame<ShelfWorld> {
  factory ShelfRushGame({
    required GameSessionController controller,
    required ProductCatalog productCatalog,
    AudioService audio = const SilentAudioService(),
    HapticsService haptics = const FlutterHapticsService(enabled: false),
    bool reduceMotion = false,
  }) {
    final BoardLayout layout = const BoardLayoutCalculator().calculate(
      Vector2(390, 844),
      hasLane: controller.state.lanes.isNotEmpty,
      laneDefs: controller.state.lanes
          .map((lane) => lane.def)
          .toList(growable: false),
    );
    final ShelfWorld world = ShelfWorld(
      controller: controller,
      productCatalog: productCatalog,
      initialLayout: layout,
      audio: audio,
      haptics: haptics,
      reduceMotion: reduceMotion,
    );
    return ShelfRushGame._(
      controller: controller,
      productCatalog: productCatalog,
      audio: audio,
      haptics: haptics,
      reduceMotion: reduceMotion,
      shelfWorld: world,
    );
  }

  ShelfRushGame._({
    required this.controller,
    required this.productCatalog,
    required this.audio,
    required this.haptics,
    required this.reduceMotion,
    required ShelfWorld shelfWorld,
  }) : _shelfWorld = shelfWorld,
       super(world: shelfWorld);

  final GameSessionController controller;
  final ProductCatalog productCatalog;
  final AudioService audio;
  final HapticsService haptics;
  final bool reduceMotion;
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
