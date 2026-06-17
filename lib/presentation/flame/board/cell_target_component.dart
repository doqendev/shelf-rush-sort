import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../../../domain/core/value_objects.dart';
import '../input/input_router.dart';

final class CellTargetComponent extends PositionComponent with TapCallbacks {
  CellTargetComponent({
    required this.address,
    required this.inputRouter,
    required this.highlighted,
    required super.position,
    required super.size,
  });

  final CellAddress address;
  final InputRouter inputRouter;
  final bool highlighted;

  @override
  void onTapDown(TapDownEvent event) {
    inputRouter.onCellTapped(address);
  }

  @override
  void render(Canvas canvas) {
    final Rect rect = size.toRect();
    final Paint paint = Paint()
      ..color = highlighted ? const Color(0x6676C893) : const Color(0x22FFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(9)),
      paint,
    );
    final Paint border = Paint()
      ..color = highlighted ? const Color(0xFF2F9D64) : const Color(0x55A8754D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = highlighted ? 2.4 : 1.2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(9)),
      border,
    );
  }
}
