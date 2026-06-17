import 'dart:async';

import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../application/game_session/game_session_controller.dart';
import '../../domain/content/product_def.dart';
import '../../infrastructure/analytics/analytics_event.dart';
import '../../infrastructure/analytics/analytics_service.dart';
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
    AnalyticsService? analytics,
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
      analytics: analytics,
      reduceMotion: reduceMotion,
      shelfWorld: world,
    );
  }

  ShelfRushGame._({
    required this.controller,
    required this.productCatalog,
    required this.audio,
    required this.haptics,
    required this.analytics,
    required this.reduceMotion,
    required ShelfWorld shelfWorld,
  }) : _shelfWorld = shelfWorld,
       super(world: shelfWorld);

  final GameSessionController controller;
  final ProductCatalog productCatalog;
  final AudioService audio;
  final HapticsService haptics;
  final AnalyticsService? analytics;
  final bool reduceMotion;
  final ShelfWorld _shelfWorld;
  double _tickAccumulator = 0;
  double _frameTelemetryElapsed = 0;
  int _frameTelemetryFrames = 0;
  int _frameSpikeCount = 0;
  int _lastLaneTickMs = 0;

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
    _recordFrame(dt);
    _tickAccumulator += dt;
    if (_tickAccumulator >= 0.1) {
      final Stopwatch laneTickTimer = Stopwatch()..start();
      controller.tick(
        Duration(milliseconds: (_tickAccumulator * 1000).round()),
      );
      laneTickTimer.stop();
      _lastLaneTickMs = laneTickTimer.elapsedMilliseconds;
      _tickAccumulator = 0;
    }
  }

  void _recordFrame(double dt) {
    _frameTelemetryElapsed += dt;
    _frameTelemetryFrames += 1;
    if (dt > 0.05) {
      _frameSpikeCount += 1;
    }
    if (_frameTelemetryElapsed < 5) {
      return;
    }
    final AnalyticsService? analytics = this.analytics;
    if (analytics != null) {
      final double fps = _frameTelemetryFrames / _frameTelemetryElapsed;
      unawaited(
        analytics.track(
          AnalyticsEvent(
            name: 'performance_frame_bucket',
            essential: true,
            parameters: <String, Object?>{
              'level_id': controller.state.level.id,
              'fps': fps.round(),
              'frame_spikes': _frameSpikeCount,
              'component_count': _shelfWorld.children.length,
              'lane_tick_time_ms': _lastLaneTickMs,
            },
          ),
        ),
      );
    }
    _frameTelemetryElapsed = 0;
    _frameTelemetryFrames = 0;
    _frameSpikeCount = 0;
  }
}
