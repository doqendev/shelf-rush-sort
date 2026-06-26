import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../design/game_colors.dart';
import '../../design/game_typography.dart';

/// The guided first-move overlay (second-pass audit P0.5): a pulsing ring on the
/// product to grab, an arrow to the slot to drop it on, a pulsing ring there,
/// and an instructional banner. Purely visual — it has no tap handling, so taps
/// reach the board beneath; the actual input restriction lives in
/// [TutorialController].
final class TutorialOverlayComponent extends PositionComponent {
  TutorialOverlayComponent({
    required this.sourceRect,
    required this.targetRect,
    required this.message,
    required super.size,
    this.reduceMotion = false,
  }) {
    priority = 800;
  }

  final Rect sourceRect;
  final Rect targetRect;
  final String message;
  final bool reduceMotion;
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (!reduceMotion) {
      _t += dt;
    }
  }

  @override
  void render(Canvas canvas) {
    final double pulse = reduceMotion ? 0.6 : 0.5 + 0.5 * math.sin(_t * 4);
    _drawArrow(canvas, sourceRect.center, targetRect.center);
    _drawRing(canvas, sourceRect, pulse, GameColors.sunny);
    _drawRing(canvas, targetRect, pulse, GameColors.leaf);
    _drawBanner(canvas);
  }

  void _drawRing(Canvas canvas, Rect cell, double pulse, Color color) {
    final Offset center = cell.center;
    final double radius = cell.shortestSide * 0.55 * (1 + 0.12 * pulse);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.5 + 0.4 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to) {
    final Paint paint = Paint()
      ..color = GameColors.ink.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, paint);
    final double angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const double headLength = 13;
    canvas.drawLine(
      to,
      to -
          Offset(
            math.cos(angle - 0.5) * headLength,
            math.sin(angle - 0.5) * headLength,
          ),
      paint,
    );
    canvas.drawLine(
      to,
      to -
          Offset(
            math.cos(angle + 0.5) * headLength,
            math.sin(angle + 0.5) * headLength,
          ),
      paint,
    );
  }

  void _drawBanner(Canvas canvas) {
    final double width = size.x - 32;
    final Rect rect = Rect.fromLTWH(16, size.y - 64, width, 48);
    final RRect rounded = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(16),
    );
    canvas.drawRRect(
      rounded.shift(const Offset(0, 4)),
      Paint()..color = GameColors.shadow(0.18),
    );
    canvas.drawRRect(rounded, Paint()..color = GameColors.surface);
    canvas.drawRRect(
      rounded,
      Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: message,
        style: const TextStyle(
          fontFamily: GameTypography.fontFamily,
          color: GameColors.ink,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: width - 24);
    painter.paint(
      canvas,
      Offset(
        rect.center.dx - painter.width / 2,
        rect.center.dy - painter.height / 2,
      ),
    );
  }
}
