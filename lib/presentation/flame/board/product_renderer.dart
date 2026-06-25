import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../../domain/blockers/blocker_def.dart';
import '../../../domain/content/product_def.dart';
import '../../../domain/core/value_objects.dart';
import '../../design/game_colors.dart';
import '../../design/game_typography.dart';
import 'cozy_sprite_cache.dart';

/// Draws a single product in the cozy v2 style: a bottom-anchored sprite from
/// the cozy art set resting on the shelf, with a soft contact shadow.
///
/// When a sprite is unavailable (mystery products, or assets not yet loaded) it
/// falls back to a rounded "blob" tinted with the SKU colour so the board stays
/// legible no matter what.
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
    final ui.Image? image = identityHidden
        ? null
        : CozySpriteCache.instance.imageForSku(productDef.skuId);

    final bool usesLayer = opacity < 1;
    if (usesLayer) {
      canvas.saveLayer(
        rect.inflate(rect.height),
        Paint()..color = Color.fromRGBO(255, 255, 255, opacity),
      );
    }

    if (image != null) {
      _drawSprite(canvas, rect, image, selected: selected);
    } else {
      _drawBlob(
        canvas,
        rect,
        productDef,
        identityHidden: identityHidden,
        selected: selected,
      );
    }

    final BlockerKind visibleBlocker = productBlocker != BlockerKind.none
        ? productBlocker
        : cellBlocker;
    if (visibleBlocker != BlockerKind.none &&
        visibleBlocker != BlockerKind.mysteryBag) {
      _paintBlockerBand(canvas, rect, visibleBlocker);
    }

    if (usesLayer) {
      canvas.restore();
    }
  }

  static void _drawSprite(
    Canvas canvas,
    Rect cell,
    ui.Image image, {
    required bool selected,
  }) {
    final double aspect = image.width / image.height;
    double h = cell.height * (selected ? 1.1 : 1.04);
    double w = h * aspect;
    final double maxW = cell.width * (selected ? 1.36 : 1.28);
    if (w > maxW) {
      w = maxW;
      h = w / aspect;
    }
    final double cx = cell.center.dx;
    final double baseY = cell.bottom + 2;
    final Rect dst = Rect.fromLTWH(cx - w / 2, baseY - h, w, h);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, baseY - h * 0.05),
        width: w * 0.72,
        height: cell.height * 0.16,
      ),
      Paint()
        ..color = GameColors.shadow(0.34)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    if (selected) {
      canvas.drawCircle(
        Offset(cx, dst.center.dy),
        w * 0.6,
        Paint()
          ..color = GameColors.sunny.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dst,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..isAntiAlias = true,
    );
  }

  static void _drawBlob(
    Canvas canvas,
    Rect cell,
    ProductDef productDef, {
    required bool identityHidden,
    required bool selected,
  }) {
    final Color color = identityHidden
        ? GameColors.mutedInk
        : _parseColor(productDef.colorHex);
    final double w = cell.width * 0.86;
    final double h = cell.height * 0.92;
    final double cx = cell.center.dx;
    final double baseY = cell.bottom;
    final Rect body = Rect.fromLTWH(cx - w / 2, baseY - h, w, h);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, baseY - 1),
        width: w * 0.8,
        height: cell.height * 0.16,
      ),
      Paint()
        ..color = GameColors.shadow(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    if (selected) {
      canvas.drawCircle(
        body.center,
        w * 0.66,
        Paint()
          ..color = GameColors.sunny.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    final RRect bodyRect = RRect.fromRectAndRadius(
      body,
      Radius.circular(_radiusForShape(productDef.shape)),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color.lerp(color, const Color(0xFFFFFFFF), 0.34)!,
            color,
          ],
        ).createShader(body),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    _paintLabel(
      canvas,
      body,
      identityHidden ? '?' : _initials(productDef),
      identityHidden ? const Color(0xFFFFFFFF) : _contrast(color),
    );
  }

  static void _paintBlockerBand(Canvas canvas, Rect rect, BlockerKind blocker) {
    final Rect band = Rect.fromLTWH(
      rect.left + rect.width * 0.08,
      rect.top + rect.height * 0.04,
      rect.width * 0.84,
      (rect.height * 0.22).clamp(14, 22),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(band, const Radius.circular(7)),
      Paint()..color = GameColors.ink.withValues(alpha: 0.86),
    );
    _paintLabel(canvas, band, _blockerLabel(blocker), const Color(0xFFFFFFFF));
  }

  static void _paintLabel(Canvas canvas, Rect area, String label, Color color) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: GameTypography.fontFamily,
          color: color,
          fontSize: (area.height * 0.42).clamp(9, 16).toDouble(),
          fontWeight: FontWeight.w700,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: area.width);
    painter.paint(
      canvas,
      Offset(
        area.left + (area.width - painter.width) / 2,
        area.top + (area.height - painter.height) / 2,
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
        return 10;
    }
  }

  static Color _parseColor(String hex) {
    final String normalized = hex.replaceFirst('#', '');
    return Color(int.parse('FF$normalized', radix: 16));
  }

  static Color _contrast(Color color) {
    return color.computeLuminance() > 0.52
        ? GameColors.ink
        : const Color(0xFFFFFFFF);
  }

  static String _initials(ProductDef product) {
    return product.displayName
        .split(' ')
        .map((String part) => part.isEmpty ? '' : part.substring(0, 1))
        .take(2)
        .join();
  }
}
