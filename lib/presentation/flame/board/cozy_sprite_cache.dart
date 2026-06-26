import 'dart:ui' as ui;

import 'package:flame/cache.dart';

import '../../../domain/content/cozy_product_visuals.dart';

/// Loads and holds the cozy product sprites (`assets/images/cozy/products/*`)
/// so the synchronous canvas renderers can draw them without per-frame async
/// work.
///
/// Each SKU has ONE stable visual via [productVisualForSku] — the same product
/// on the board, in previews, and on the collection screen, never reassigned
/// per level (second-pass audit M3 / P0.1). The level packs are colour-mapped
/// so no level shows two active SKUs with the same product (enforced by the
/// content validator).
class CozySpriteCache {
  CozySpriteCache._();

  static final CozySpriteCache instance = CozySpriteCache._();

  final Map<String, ui.Image> _images = <String, ui.Image>{};
  bool _loaded = false;

  /// Preloads every cozy product sprite into memory. Safe to call repeatedly.
  Future<void> ensureLoaded(Images images) async {
    if (_loaded) {
      return;
    }
    for (final String name in kCozyProducts) {
      _images[name] = await images.load('cozy/products/$name.png');
    }
    _loaded = true;
  }

  ui.Image? imageForName(String name) => _images[name];

  /// The stable product sprite key for [skuId].
  String spriteNameForSku(String skuId) => productVisualForSku(skuId);

  ui.Image? imageForSku(String skuId) => _images[spriteNameForSku(skuId)];
}
