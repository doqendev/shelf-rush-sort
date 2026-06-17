import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../../domain/core/value_objects.dart';

final class RackBackdropComponent extends PositionComponent {
  RackBackdropComponent({required super.position, required super.size});

  @override
  void render(Canvas canvas) {
    final Rect rect = size.toRect();
    final RRect outer = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(14),
    );
    final Paint shadow = Paint()..color = const Color(0x33000000);
    canvas.drawRRect(outer.shift(const Offset(0, 5)), shadow);

    final Paint backing = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFFFFE9BE), Color(0xFFF4C987)],
      ).createShader(rect);
    canvas.drawRRect(outer, backing);

    final Paint frame = Paint()
      ..color = const Color(0xFFA9653C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    canvas.drawRRect(outer.deflate(3.5), frame);

    final double rowHeight = rect.height / boardRows;
    final double columnWidth = rect.width / boardColumns;
    final Paint shelfBoard = Paint()..color = const Color(0xFF7A452C);
    final Paint divider = Paint()..color = const Color(0xFF9B603A);
    for (var row = 1; row < boardRows; row += 1) {
      final double y = row * rowHeight;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(6, y - 3, rect.width - 12, 6),
          const Radius.circular(3),
        ),
        shelfBoard,
      );
    }
    for (var column = 1; column < boardColumns; column += 1) {
      final double x = column * columnWidth;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 2.5, 7, 5, rect.height - 14),
          const Radius.circular(3),
        ),
        divider,
      );
    }
    for (var row = 0; row < boardRows; row += 1) {
      final double y = (row + 1) * rowHeight - 9;
      canvas.drawRect(Rect.fromLTWH(8, y, rect.width - 16, 8), shelfBoard);
    }
  }
}
