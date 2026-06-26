import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../../domain/game/move.dart';
import '../../design/game_colors.dart';
import '../../design/game_typography.dart';

/// Emphasis drawn over the shelf slot the dragged product is currently aimed
/// at (second-pass audit P1.2). A triple-completing slot glows gold with a "3"
/// badge; any other legal slot glows green (stronger for a pair). Sits above
/// the board but below the dragged product so the outcome is visible before
/// release.
final class HoverTargetComponent extends PositionComponent {
  HoverTargetComponent({
    required this.quality,
    required super.position,
    required super.size,
  }) {
    priority = 50;
  }

  MoveQuality quality;

  bool get _completesTriple =>
      quality == MoveQuality.completesTriple ||
      quality == MoveQuality.revealEnabling;

  @override
  void render(Canvas canvas) {
    final Rect rect = size.toRect();
    final RRect shape = RRect.fromRectAndRadius(
      rect.deflate(1),
      const Radius.circular(8),
    );
    final bool triple = _completesTriple;
    final bool pair = quality == MoveQuality.createsPair;
    final Color color = triple ? GameColors.sunny : GameColors.leaf;

    canvas.drawRRect(
      shape,
      Paint()
        ..color = color.withValues(
          alpha: triple
              ? 0.5
              : pair
              ? 0.42
              : 0.3,
        ),
    );
    canvas.drawRRect(
      shape,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = triple ? 4 : 3,
    );
    if (triple) {
      canvas.drawRRect(
        shape,
        Paint()
          ..color = color.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      _paintTripleBadge(canvas, rect);
    }
  }

  void _paintTripleBadge(Canvas canvas, Rect rect) {
    final Offset center = Offset(rect.center.dx, rect.top + 3);
    canvas.drawCircle(center, 9, Paint()..color = GameColors.ink);
    final TextPainter painter = TextPainter(
      text: const TextSpan(
        text: '3',
        style: TextStyle(
          fontFamily: GameTypography.fontFamily,
          color: GameColors.sunny,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }
}
