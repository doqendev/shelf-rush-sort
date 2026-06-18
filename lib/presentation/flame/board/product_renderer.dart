import 'package:flutter/painting.dart';

import '../../../domain/blockers/blocker_def.dart';
import '../../../domain/content/product_def.dart';
import '../../../domain/core/value_objects.dart';

final class ProductRenderer {
  const ProductRenderer._();

  static void render(
    Canvas canvas,
    Rect rect, {
    required ProductDef productDef,
    required bool selected,
    required BlockerKind cellBlocker,
    required BlockerKind productBlocker,
    double opacity = 1,
  }) {
    final bool identityHidden =
        productBlocker == BlockerKind.mysteryBag ||
        cellBlocker == BlockerKind.mysteryBag;
    final Color color = identityHidden
        ? const Color(0xFF7D756D)
        : _parseColor(productDef.colorHex);
    final bool usesOpacityLayer = opacity < 1;
    if (usesOpacityLayer) {
      canvas.saveLayer(
        rect,
        Paint()..color = Color.fromRGBO(255, 255, 255, opacity),
      );
    }
    final Paint shadow = Paint()..color = const Color(0x33000000);
    canvas.drawOval(rect.deflate(4).translate(0, rect.height * 0.16), shadow);
    final Paint body = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color.lerp(color, const Color(0xFFFFFFFF), 0.34)!,
          color,
        ],
      ).createShader(rect);
    final RRect bodyRect = RRect.fromRectAndRadius(
      rect.deflate(selected ? 2 : 5),
      Radius.circular(_radiusForShape(productDef.shape)),
    );
    canvas.drawRRect(bodyRect, body);
    final Paint shine = Paint()..color = const Color(0x55FFFFFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rect.width * 0.22,
          rect.height * 0.14,
          rect.width * 0.22,
          rect.height * 0.18,
        ),
        const Radius.circular(8),
      ),
      shine,
    );
    if (selected) {
      final Paint selectedPaint = Paint()
        ..color = const Color(0xFF1D7F5A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRRect(bodyRect, selectedPaint);
    }
    final String label = identityHidden
        ? '?'
        : productDef.displayName
              .split(' ')
              .map((String part) => part.isEmpty ? '' : part.substring(0, 1))
              .take(2)
              .join();
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: _contrastingTextColor(color),
          fontSize: rect.height * 0.26,
          fontWeight: FontWeight.w800,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);
    painter.paint(
      canvas,
      Offset((rect.width - painter.width) / 2, rect.height * 0.36),
    );
    final BlockerKind visibleBlocker = productBlocker != BlockerKind.none
        ? productBlocker
        : cellBlocker;
    if (visibleBlocker != BlockerKind.none) {
      _paintBlockerBand(canvas, rect, visibleBlocker);
    }
    if (usesOpacityLayer) {
      canvas.restore();
    }
  }

  static void _paintBlockerBand(Canvas canvas, Rect rect, BlockerKind blocker) {
    final Rect band = Rect.fromLTWH(
      rect.width * 0.11,
      rect.height * 0.06,
      rect.width * 0.78,
      rect.height * 0.22,
    );
    final Paint paint = Paint()..color = const Color(0xCC2D211B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(band, const Radius.circular(6)),
      paint,
    );
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: _blockerLabel(blocker),
        style: TextStyle(
          color: const Color(0xFFFFFFFF),
          fontSize: (rect.height * 0.12).clamp(8, 11).toDouble(),
          fontWeight: FontWeight.w800,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: band.width - 4);
    painter.paint(
      canvas,
      Offset(
        band.left + (band.width - painter.width) / 2,
        band.top + (band.height - painter.height) / 2,
      ),
    );
  }

  static String _blockerLabel(BlockerKind blocker) {
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

  static double _radiusForShape(ProductShape shape) {
    switch (shape) {
      case ProductShape.bottle:
      case ProductShape.can:
      case ProductShape.jar:
        return 14;
      case ProductShape.pouch:
      case ProductShape.produce:
        return 18;
      case ProductShape.box:
      case ProductShape.carton:
      case ProductShape.toy:
        return 8;
    }
  }

  static Color _parseColor(String hex) {
    final String normalized = hex.replaceFirst('#', '');
    return Color(int.parse('FF$normalized', radix: 16));
  }

  static Color _contrastingTextColor(Color color) {
    return color.computeLuminance() > 0.52
        ? const Color(0xFF35261E)
        : const Color(0xFFFFFFFF);
  }
}
