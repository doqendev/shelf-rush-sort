import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

import '../../../domain/content/product_def.dart';
import '../input/input_router.dart';

final class LaneProductComponent extends PositionComponent with TapCallbacks {
  LaneProductComponent({
    required this.laneId,
    required this.productDef,
    required this.inputRouter,
    required super.position,
    required super.size,
  });

  final String laneId;
  final ProductDef productDef;
  final InputRouter inputRouter;

  @override
  void onTapDown(TapDownEvent event) {
    inputRouter.onLaneProductTapped(laneId);
  }

  @override
  void render(Canvas canvas) {
    final Rect rect = size.toRect();
    final Color color = _parseColor(productDef.colorHex);
    final Paint body = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(12)),
      body,
    );
    final Paint border = Paint()
      ..color = const Color(0xFF2E4450)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(12)),
      border,
    );
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: productDef.displayName.substring(0, 1),
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);
    painter.paint(
      canvas,
      Offset(
        (rect.width - painter.width) / 2,
        (rect.height - painter.height) / 2,
      ),
    );
  }

  Color _parseColor(String hex) {
    final String normalized = hex.replaceFirst('#', '');
    return Color(int.parse('FF$normalized', radix: 16));
  }
}
