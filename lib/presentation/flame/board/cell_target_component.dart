import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

import '../../../domain/blockers/blocker_def.dart';
import '../../../domain/core/value_objects.dart';
import '../input/input_router.dart';

final class CellTargetComponent extends PositionComponent with TapCallbacks {
  CellTargetComponent({
    required this.address,
    required this.inputRouter,
    required this.highlighted,
    this.blocker = BlockerKind.none,
    required super.position,
    required super.size,
  });

  final CellAddress address;
  final InputRouter inputRouter;
  final bool highlighted;
  final BlockerKind blocker;

  @override
  void onTapDown(TapDownEvent event) {
    inputRouter.onCellTapped(address);
  }

  @override
  void render(Canvas canvas) {
    final Rect rect = size.toRect();
    final bool hasBlocker = blocker != BlockerKind.none;
    if (!highlighted && !hasBlocker) {
      final Paint resting = Paint()..color = const Color(0x08FFFFFF);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(7)),
        resting,
      );
      return;
    }
    final Paint paint = Paint()
      ..color = hasBlocker
          ? const Color(0x66B76A4E)
          : highlighted
          ? const Color(0x6676C893)
          : const Color(0x22FFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(9)),
      paint,
    );
    final Paint border = Paint()
      ..color = hasBlocker
          ? const Color(0xFFD98255)
          : highlighted
          ? const Color(0xFF2F9D64)
          : const Color(0x55A8754D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = highlighted || hasBlocker ? 2.4 : 1.2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(9)),
      border,
    );
    if (hasBlocker) {
      _paintBlockerBadge(canvas, rect, blocker);
    }
  }

  void _paintBlockerBadge(Canvas canvas, Rect rect, BlockerKind blocker) {
    final Rect badge = Rect.fromCenter(
      center: Offset(rect.width / 2, rect.height / 2),
      width: rect.width * 0.72,
      height: rect.height * 0.34,
    );
    final Paint badgePaint = Paint()..color = const Color(0xCC3D2A22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(badge, const Radius.circular(6)),
      badgePaint,
    );
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: _labelFor(blocker),
        style: TextStyle(
          color: const Color(0xFFFFFFFF),
          fontSize: (rect.height * 0.15).clamp(8, 12).toDouble(),
          fontWeight: FontWeight.w800,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: badge.width - 4);
    painter.paint(
      canvas,
      Offset(
        badge.left + (badge.width - painter.width) / 2,
        badge.top + (badge.height - painter.height) / 2,
      ),
    );
  }

  String _labelFor(BlockerKind blocker) {
    return switch (blocker) {
      BlockerKind.none => '',
      BlockerKind.locked => 'LOCK',
      BlockerKind.tape => 'TAPE',
      BlockerKind.frozen => 'ICE',
      BlockerKind.frost => 'FROST',
      BlockerKind.cover => 'COVER',
      BlockerKind.crate => 'CRATE',
      BlockerKind.mysteryBag => '?',
    };
  }
}
