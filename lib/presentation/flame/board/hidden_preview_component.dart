import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../../domain/content/product_def.dart';
import '../../../domain/game/hidden_preview.dart';
import '../../design/game_colors.dart';
import 'cozy_sprite_cache.dart';

/// Renders the products waiting *behind* the front row as darkened "shadow"
/// sprites that peek above the front items — matching the design's dimmed
/// back-stack treatment.
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
    final Rect rect = size.toRect();
    final bool reveal =
        revealed ||
        mode == HiddenPreviewMode.exactDim ||
        mode == HiddenPreviewMode.silhouette;
    if (!reveal) {
      _paintHiddenStack(canvas, rect);
      return;
    }
    _paintBackSprites(canvas, rect);
  }

  void _paintHiddenStack(Canvas canvas, Rect rect) {
    final Paint paint = Paint()..color = GameColors.ink.withValues(alpha: 0.32);
    final int columns = count.clamp(0, 3);
    final double slotWidth = rect.width / 3;
    for (var index = 0; index < columns; index += 1) {
      final Rect blob = Rect.fromLTWH(
        index * slotWidth + slotWidth * 0.16,
        rect.height * 0.5,
        slotWidth * 0.68,
        rect.height * 0.26,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(blob, const Radius.circular(7)),
        paint,
      );
    }
  }

  void _paintBackSprites(Canvas canvas, Rect rect) {
    final double slotWidth = rect.width / 3;
    final Paint darken = Paint()
      ..colorFilter = ColorFilter.mode(
        GameColors.ink.withValues(alpha: 0.58),
        BlendMode.srcATop,
      )
      ..filterQuality = FilterQuality.medium;
    for (var index = 0; index < 3; index += 1) {
      final ProductDef? product = index < previewProducts.length
          ? previewProducts[index]
          : null;
      if (product == null) {
        continue;
      }
      final ui.Image? image = CozySpriteCache.instance.imageForSku(
        product.skuId,
      );
      if (image == null) {
        continue;
      }
      final double aspect = image.width / image.height;
      double h = rect.height * 0.6;
      double w = h * aspect;
      if (w > slotWidth * 1.1) {
        w = slotWidth * 1.1;
        h = w / aspect;
      }
      final double cx = index * slotWidth + slotWidth / 2;
      final double baseY = rect.height * 0.74;
      final Rect dst = Rect.fromLTWH(cx - w / 2, baseY - h, w, h);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        dst,
        darken,
      );
    }
  }
}
