import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../../domain/content/product_def.dart';
import '../../../domain/game/hidden_preview.dart';

final class HiddenPreviewComponent extends PositionComponent {
  HiddenPreviewComponent({
    required this.count,
    required this.mode,
    required this.revealed,
    required List<ProductDef?> previewProducts,
    required super.position,
    required super.size,
  }) : previewProducts = List<ProductDef?>.unmodifiable(previewProducts);

  final int count;
  final HiddenPreviewMode mode;
  final bool revealed;
  final List<ProductDef?> previewProducts;

  @override
  void render(Canvas canvas) {
    if (count <= 0) {
      return;
    }
    if (!revealed && mode == HiddenPreviewMode.hidden) {
      _paintHiddenStack(canvas);
      return;
    }
    _paintPreviewCells(canvas);
  }

  void _paintHiddenStack(Canvas canvas) {
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

  void _paintPreviewCells(Canvas canvas) {
    final Rect rect = size.toRect();
    final double gap = 4;
    final double slotWidth = (rect.width - gap * 2) / 3;
    final bool exact = revealed || mode == HiddenPreviewMode.exactDim;
    for (var index = 0; index < 3; index += 1) {
      final ProductDef? product = index < previewProducts.length
          ? previewProducts[index]
          : null;
      final Rect slot = Rect.fromLTWH(
        index * (slotWidth + gap),
        0,
        slotWidth,
        rect.height * 0.28,
      );
      switch (mode) {
        case HiddenPreviewMode.exactDim:
        case HiddenPreviewMode.silhouette:
        case HiddenPreviewMode.mysteryBag:
        case HiddenPreviewMode.hidden:
          _paintSlot(canvas, slot, product, exact: exact);
      }
    }
  }

  void _paintSlot(
    Canvas canvas,
    Rect slot,
    ProductDef? product, {
    required bool exact,
  }) {
    if (product == null) {
      final Paint empty = Paint()
        ..color = const Color(0x22000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRRect(
        RRect.fromRectAndRadius(slot.deflate(1), const Radius.circular(4)),
        empty,
      );
      return;
    }
    if (mode == HiddenPreviewMode.mysteryBag && !revealed) {
      _paintMysteryBag(canvas, slot);
      return;
    }
    final Color color = exact
        ? _parseColor(product.colorHex)
        : const Color(0x996B625B);
    final Paint body = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(slot.deflate(1), const Radius.circular(5)),
      body,
    );
    if (exact) {
      _paintLabel(
        canvas,
        slot,
        _initials(product),
        _contrastingTextColor(color),
      );
    }
  }

  void _paintMysteryBag(Canvas canvas, Rect slot) {
    final Paint body = Paint()..color = const Color(0xCC4C3D35);
    canvas.drawRRect(
      RRect.fromRectAndRadius(slot.deflate(1), const Radius.circular(7)),
      body,
    );
    _paintLabel(canvas, slot, '?', const Color(0xFFFFFFFF));
  }

  void _paintLabel(Canvas canvas, Rect slot, String label, Color color) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: (slot.height * 0.42).clamp(8, 12).toDouble(),
          fontWeight: FontWeight.w800,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: slot.width);
    painter.paint(
      canvas,
      Offset(
        slot.left + (slot.width - painter.width) / 2,
        slot.top + (slot.height - painter.height) / 2,
      ),
    );
  }

  String _initials(ProductDef product) {
    return product.displayName
        .split(' ')
        .map((String part) => part.isEmpty ? '' : part.substring(0, 1))
        .take(2)
        .join();
  }

  Color _parseColor(String hex) {
    final String normalized = hex.replaceFirst('#', '');
    return Color(int.parse('FF$normalized', radix: 16));
  }

  Color _contrastingTextColor(Color color) {
    return color.computeLuminance() > 0.52
        ? const Color(0xFF35261E)
        : const Color(0xFFFFFFFF);
  }
}
