import 'dart:ui';

import 'package:flame/components.dart';

import '../../../domain/moving_lanes/moving_lane_def.dart';

final class LanePathComponent extends PositionComponent {
  LanePathComponent({
    required this.orientation,
    required this.progress,
    required this.slowed,
    required this.exhausted,
    required super.position,
    required super.size,
  });

  final LaneOrientation orientation;
  final double progress;
  final bool slowed;
  final bool exhausted;

  @override
  void render(Canvas canvas) {
    final Rect rect = size.toRect();
    final Paint rail = Paint()
      ..color = exhausted
          ? const Color(0xFF6F6F6F)
          : slowed
          ? const Color(0xFF527DA2)
          : const Color(0xFF6B7F8C);
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
    if (orientation == LaneOrientation.horizontal) {
      for (var x = 14.0; x < rect.width; x += 22) {
        canvas.drawLine(Offset(x, 7), Offset(x + 10, rect.height - 7), tick);
      }
      final Paint progressPaint = Paint()..color = const Color(0xAA2F9D64);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(6, rect.height - 8, (rect.width - 12) * progress, 4),
          const Radius.circular(4),
        ),
        progressPaint,
      );
    } else {
      for (var y = 14.0; y < rect.height; y += 22) {
        canvas.drawLine(Offset(7, y), Offset(rect.width - 7, y + 10), tick);
      }
      final Paint progressPaint = Paint()..color = const Color(0xAA2F9D64);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.width - 8, 6, 4, (rect.height - 12) * progress),
          const Radius.circular(4),
        ),
        progressPaint,
      );
    }
  }
}
