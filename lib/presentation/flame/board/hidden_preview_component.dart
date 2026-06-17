import 'dart:ui';

import 'package:flame/components.dart';

final class HiddenPreviewComponent extends PositionComponent {
  HiddenPreviewComponent({
    required this.count,
    required super.position,
    required super.size,
  });

  final int count;

  @override
  void render(Canvas canvas) {
    if (count <= 0) {
      return;
    }
    final Paint paint = Paint()..color = const Color(0x66000000);
    for (var index = 0; index < count.clamp(0, 3); index += 1) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(index * 7, 0, size.x - 14, size.y * 0.22),
          const Radius.circular(5),
        ),
        paint,
      );
    }
  }
}
