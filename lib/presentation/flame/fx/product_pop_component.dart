import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// A single cleared product that squashes, then pops outward and fades — the
/// per-product clear animation the second-pass audit asked for (P0.2 / M2:
/// "products scale/pop out individually"). Plays once over its old slot and
/// removes itself; spawned alongside the compartment celebration burst.
final class ProductPopComponent extends PositionComponent {
  ProductPopComponent({
    required this.image,
    required super.position,
    required super.size,
    this.delay = 0,
  }) {
    priority = 880;
  }

  final ui.Image? image;

  /// Stagger before this product begins its pop, so a cleared trio reads as
  /// three quick beats rather than one.
  final double delay;

  double _elapsed = 0;
  static const double _duration = 0.22;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed - delay >= _duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final ui.Image? sprite = image;
    if (sprite == null) {
      return;
    }
    final double local = _elapsed - delay;
    double scale;
    double opacity;
    double rise;
    if (local <= 0) {
      // Still in its stagger delay — hold the product in place.
      scale = 1;
      opacity = 1;
      rise = 0;
    } else {
      final double p = (local / _duration).clamp(0.0, 1.0);
      if (p < 0.3) {
        // Anticipation squash.
        scale = 1 - 0.12 * (p / 0.3);
        opacity = 1;
        rise = 0;
      } else {
        // Pop outward, rise and fade.
        final double q = (p - 0.3) / 0.7;
        scale = 0.88 + 0.45 * q;
        opacity = 1 - q;
        rise = 14 * q;
      }
    }

    final Rect cell = size.toRect();
    final double aspect = sprite.width / sprite.height;
    double h = cell.height * 1.04 * scale;
    double w = h * aspect;
    final double maxW = cell.width * 1.28 * scale;
    if (w > maxW) {
      w = maxW;
      h = w / aspect;
    }
    final double cx = cell.center.dx;
    final double baseY = cell.bottom + 2 - rise;
    final Rect dst = Rect.fromLTWH(cx - w / 2, baseY - h, w, h);
    canvas.drawImageRect(
      sprite,
      Rect.fromLTWH(0, 0, sprite.width.toDouble(), sprite.height.toDouble()),
      dst,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..isAntiAlias = true
        ..color = Color.fromRGBO(255, 255, 255, opacity.clamp(0.0, 1.0)),
    );
  }
}
