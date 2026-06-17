import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

final class CompartmentComponent extends PositionComponent {
  CompartmentComponent({
    required this.locked,
    required this.decorative,
    required super.position,
    required super.size,
  });

  final bool locked;
  final bool decorative;

  @override
  void render(Canvas canvas) {
    final Rect rect = size.toRect();
    final Paint shadow = Paint()..color = const Color(0x30000000);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.translate(0, 4), const Radius.circular(8)),
      shadow,
    );
    final Paint shelfPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFFD09A62), Color(0xFF9B603A)],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      shelfPaint,
    );
    final Paint inner = Paint()..color = const Color(0xFFFFF4D7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(7), const Radius.circular(6)),
      inner,
    );
    final Paint lip = Paint()..color = const Color(0xFF7A452C);
    canvas.drawRect(Rect.fromLTWH(0, rect.height - 10, rect.width, 10), lip);
    if (locked || decorative) {
      final Paint cover = Paint()..color = const Color(0xAAE7C988);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(8), const Radius.circular(7)),
        cover,
      );
      final Paint stripe = Paint()
        ..color = const Color(0x88A86838)
        ..strokeWidth = 4;
      for (var x = -rect.height; x < rect.width; x += 18) {
        canvas.drawLine(
          Offset(x, rect.height),
          Offset(x + rect.height, 0),
          stripe,
        );
      }
    }
  }
}
