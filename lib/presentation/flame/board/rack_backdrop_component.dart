import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../design/game_colors.dart';

/// The cozy v2 shelf rack: a thick-outlined, rounded board with a chunky drop
/// "lip", holding a 3×5 grid of gradient shelf slots that each carry their own
/// little shelf lip.
final class RackBackdropComponent extends PositionComponent {
  RackBackdropComponent({
    required this.slotRects,
    this.bodyColor = GameColors.shelf,
    this.lipColor = GameColors.shelfLip,
    required super.position,
    required super.size,
  });

  /// Local-space rects (relative to this component) of the 15 shelf slots.
  final List<Rect> slotRects;
  final Color bodyColor;
  final Color lipColor;

  static const Radius _bodyRadius = Radius.circular(20);
  static const Radius _slotRadius = Radius.circular(6);

  @override
  void render(Canvas canvas) {
    final Rect rect = size.toRect();
    final RRect body = RRect.fromRectAndRadius(rect, _bodyRadius);

    // Ambient soft shadow + chunky lip offset (the "0 7px 0 lip" sticker drop).
    canvas.drawRRect(
      body.shift(const Offset(0, 12)),
      Paint()
        ..color = GameColors.shadow(0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawRRect(body.shift(const Offset(0, 7)), Paint()..color = lipColor);

    // Rack body.
    canvas.drawRRect(body, Paint()..color = bodyColor);

    // Inner top highlight.
    canvas.save();
    canvas.clipRRect(body);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, rect.width, 5),
      Paint()..color = const Color(0x3DFFFFFF),
    );
    canvas.restore();

    // 4px ink frame.
    canvas.drawRRect(
      body.deflate(2),
      Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    for (final Rect slot in slotRects) {
      _drawSlot(canvas, slot);
    }
  }

  void _drawSlot(Canvas canvas, Rect slot) {
    final RRect r = RRect.fromRectAndRadius(slot, _slotRadius);
    canvas.drawRRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[GameColors.cellTop, GameColors.cellBottom],
        ).createShader(slot),
    );

    canvas.save();
    canvas.clipRRect(r);
    // Soft inset shadow at the top of the slot.
    canvas.drawRect(
      Rect.fromLTWH(slot.left, slot.top, slot.width, 8),
      Paint()
        ..color = GameColors.shadow(0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Shelf lip at the bottom of the slot.
    canvas.drawRect(
      Rect.fromLTWH(slot.left, slot.bottom - 6, slot.width, 6),
      Paint()..color = lipColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(slot.left, slot.bottom - 10, slot.width, 4),
      Paint()..color = GameColors.shadow(0.12),
    );
    canvas.restore();
  }
}
