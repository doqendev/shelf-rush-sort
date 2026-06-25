import 'dart:ui' as ui;

import 'package:flame/cache.dart';

/// Loads and holds the cozy product sprites (`assets/images/cozy/object-no/*`)
/// so the synchronous canvas renderers can draw them without per-frame async
/// work.
///
/// The game ships 60 metadata-driven SKUs but the cozy art set has 11 products,
/// so each SKU is mapped onto a sprite deterministically. Sequential SKUs map
/// to distinct sprites, which means the handful of products used within any one
/// level rarely collide.
class CozySpriteCache {
  CozySpriteCache._();

  static final CozySpriteCache instance = CozySpriteCache._();

  /// The 11 cozy products, in the fixed order used for SKU assignment.
  static const List<String> productNames = <String>[
    'strawberry',
    'popsicle',
    'banana',
    'honey',
    'smoothie',
    'carrot',
    'lemon-juice',
    'orange-soda',
    'vase',
    'cactus',
    'popsicle-2',
  ];

  final Map<String, ui.Image> _images = <String, ui.Image>{};
  bool _loaded = false;

  /// Preloads every cozy product sprite into memory. Safe to call repeatedly.
  Future<void> ensureLoaded(Images images) async {
    if (_loaded) {
      return;
    }
    for (final String name in productNames) {
      _images[name] = await images.load('cozy/object-no/$name.png');
    }
    _loaded = true;
  }

  ui.Image? imageForName(String name) => _images[name];

  /// Stable mapping from a SKU id to one of the cozy sprite names.
  String spriteNameForSku(String skuId) {
    return productNames[_skuIndex(skuId) % productNames.length];
  }

  ui.Image? imageForSku(String skuId) => _images[spriteNameForSku(skuId)];

  int _skuIndex(String skuId) {
    final Match? match = RegExp(r'(\d+)$').firstMatch(skuId);
    if (match != null) {
      final int? parsed = int.tryParse(match.group(1)!);
      if (parsed != null) {
        return parsed;
      }
    }
    return skuId.hashCode.abs();
  }
}
