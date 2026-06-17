import 'dart:ui';

import 'package:flame/components.dart';

final class LanePathComponent extends PositionComponent {
  LanePathComponent({required super.position, required super.size});

  @override
  void render(Canvas canvas) {
    final Rect rect = size.toRect();
    final Paint rail = Paint()..color = const Color(0xFF6B7F8C);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      rail,
    );
    final Paint belt = Paint()..color = const Color(0xFFE4EDF1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(5), const Radius.circular(8)),
      belt,
    );
    final Paint tick = Paint()
      ..color = const Color(0x556B7F8C)
      ..strokeWidth = 2;
    for (var x = 14.0; x < rect.width; x += 22) {
      canvas.drawLine(Offset(x, 7), Offset(x + 10, rect.height - 7), tick);
    }
  }
}
