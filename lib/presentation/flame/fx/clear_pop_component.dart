import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../design/game_colors.dart';

/// A short, self-removing celebration burst played over a shelf slot when a
/// triple clears: an expanding ring plus sparkles flying outward. Later cascade
/// steps read hotter (blossom pink) than the first clear (sunny yellow).
///
/// It is only spawned when motion is allowed (see [FxDirector]); the retained
/// world preserves it across board rebuilds until it finishes.
final class ClearPopComponent extends PositionComponent {
  ClearPopComponent({
    required super.position,
    required super.size,
    required this.comboIndex,
  }) {
    priority = 900;
  }

  final int comboIndex;
  double _t = 0;

  static const double _durationSeconds = 0.26;
  static const int _sparkleCount = 6;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt / _durationSeconds;
    if (_t >= 1) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final double t = _t.clamp(0.0, 1.0);
    final double fade = 1 - t;
    final Rect rect = size.toRect();
    final Offset center = rect.center;
    final double maxRadius = rect.shortestSide * 0.5;
    final Color tint = comboIndex >= 2 ? GameColors.blossom : GameColors.sunny;

    // Expanding ring.
    canvas.drawCircle(
      center,
      maxRadius * (0.35 + 0.75 * t),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * fade
        ..color = tint.withValues(alpha: fade * 0.9),
    );

    // Sparkles flying outward.
    final double distance = maxRadius * (0.2 + 0.9 * t);
    final double dotRadius = (3.5 * fade).clamp(0.0, 4.0);
    final Paint dot = Paint()..color = tint.withValues(alpha: fade);
    for (var i = 0; i < _sparkleCount; i += 1) {
      final double angle = (math.pi * 2 / _sparkleCount) * i - math.pi / 2;
      canvas.drawCircle(
        center + Offset(math.cos(angle) * distance, math.sin(angle) * distance),
        dotRadius,
        dot,
      );
    }
  }
}
