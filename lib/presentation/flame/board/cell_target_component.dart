import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

import '../../../domain/blockers/blocker_def.dart';
import '../../../domain/core/value_objects.dart';
import '../../design/game_colors.dart';
import '../../design/game_typography.dart';
import '../input/input_router.dart';

/// An empty shelf cell. The slot background is drawn by the rack, so this only
/// adds the legal-target highlight and any blocker badge, and handles taps.
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

    if (highlighted) {
      final RRect r = RRect.fromRectAndRadius(
        rect.deflate(1),
        const Radius.circular(8),
      );
      canvas.drawRRect(
        r,
        Paint()..color = GameColors.leaf.withValues(alpha: 0.34),
      );
      canvas.drawRRect(
        r,
        Paint()
          ..color = GameColors.leaf
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    if (hasBlocker) {
      _paintBlockerBadge(canvas, rect, blocker);
    }
  }

  void _paintBlockerBadge(Canvas canvas, Rect rect, BlockerKind blocker) {
    final Rect badge = Rect.fromCenter(
      center: Offset(rect.width / 2, rect.height / 2),
      width: rect.width * 0.82,
      height: (rect.height * 0.4).clamp(16, 26).toDouble(),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(badge, const Radius.circular(8)),
      Paint()..color = GameColors.ink.withValues(alpha: 0.86),
    );
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: _labelFor(blocker),
        style: TextStyle(
          fontFamily: GameTypography.fontFamily,
          color: const Color(0xFFFFFFFF),
          fontSize: (rect.height * 0.16).clamp(9, 13).toDouble(),
          fontWeight: FontWeight.w700,
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
