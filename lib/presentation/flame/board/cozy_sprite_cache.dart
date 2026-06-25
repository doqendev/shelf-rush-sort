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

  /// Per-level SKU -> sprite assignment ensuring distinct match identities in
  /// the active level never share a sprite. Empty outside an active level.
  Map<String, String> _levelAssignment = const <String, String>{};

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

  /// Number of visually distinct cozy product identities available.
  static int get visualBudget => productNames.length;

  /// Resolves the sprite for [skuId]. Prefers the active level's collision-free
  /// assignment (see [assignLevel]); falls back to a global stable mapping when
  /// no level is active.
  String spriteNameForSku(String skuId) {
    final String? assigned = _levelAssignment[skuId];
    if (assigned != null) {
      return assigned;
    }
    return productNames[_skuIndex(skuId) % productNames.length];
  }

  ui.Image? imageForSku(String skuId) => _images[spriteNameForSku(skuId)];

  /// Assigns every distinct SKU in the active level a unique sprite so two
  /// different match identities never share artwork ("artwork is the truth").
  /// SKUs are sorted for deterministic, stable assignment; any beyond
  /// [visualBudget] wrap and collide — a content failure that [visualCollisions]
  /// reports.
  void assignLevel(Iterable<String> skuIds) {
    final List<String> sorted = skuIds.toSet().toList()..sort();
    final Map<String, String> assignment = <String, String>{};
    for (var index = 0; index < sorted.length; index += 1) {
      assignment[sorted[index]] = productNames[index % productNames.length];
    }
    _levelAssignment = Map<String, String>.unmodifiable(assignment);
  }

  /// Reverts to the global fallback mapping (no active level).
  void clearLevelAssignment() {
    _levelAssignment = const <String, String>{};
  }

  /// Groups of distinct SKUs that would share a sprite under [assignLevel] for
  /// [skuIds]. Empty when every SKU is visually unique; any non-empty entry is
  /// a different-SKU/same-sprite collision that must fail content validation.
  static Map<String, List<String>> visualCollisions(Iterable<String> skuIds) {
    final List<String> sorted = skuIds.toSet().toList()..sort();
    final Map<String, List<String>> byVisual = <String, List<String>>{};
    for (var index = 0; index < sorted.length; index += 1) {
      byVisual
          .putIfAbsent(
            productNames[index % productNames.length],
            () => <String>[],
          )
          .add(sorted[index]);
    }
    byVisual.removeWhere((_, List<String> skus) => skus.length < 2);
    return byVisual;
  }

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
