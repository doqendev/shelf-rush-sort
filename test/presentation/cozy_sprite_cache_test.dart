import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/presentation/flame/board/cozy_sprite_cache.dart';

/// P0.1 — "artwork is the truth": two different SKUs active in the same level
/// must never render with the same sprite. These cover the per-level injective
/// assignment and the collision detector that guards content.
void main() {
  group('CozySpriteCache visual identity', () {
    tearDown(CozySpriteCache.instance.clearLevelAssignment);

    test('distinct SKUs within the budget get distinct sprites', () {
      // sku_002 and sku_013 are 11 apart — the exact collision the review
      // reproduced under the old `% 11` mapping.
      const List<String> skus = <String>[
        'sku_002',
        'sku_013',
        'sku_024',
        'sku_000',
        'sku_011',
      ];
      CozySpriteCache.instance.assignLevel(skus);

      final List<String> sprites = skus
          .map(CozySpriteCache.instance.spriteNameForSku)
          .toList();
      expect(sprites.toSet().length, sprites.length);
      expect(
        CozySpriteCache.instance.spriteNameForSku('sku_002'),
        isNot(CozySpriteCache.instance.spriteNameForSku('sku_013')),
      );
    });

    test('visualCollisions is empty within the budget, non-empty over it', () {
      final List<String> within = <String>[
        for (var i = 0; i < CozySpriteCache.visualBudget; i += 1) 'sku_$i',
      ];
      expect(CozySpriteCache.visualCollisions(within), isEmpty);

      final List<String> over = <String>[
        for (var i = 0; i < CozySpriteCache.visualBudget + 1; i += 1) 'sku_$i',
      ];
      expect(CozySpriteCache.visualCollisions(over), isNotEmpty);
    });

    test('assignment wraps only when a level exceeds the visual budget', () {
      final List<String> over = <String>[
        for (var i = 0; i < CozySpriteCache.visualBudget + 3; i += 1) 'sku_$i',
      ];
      CozySpriteCache.instance.assignLevel(over);
      final Set<String> distinctSprites = over
          .map(CozySpriteCache.instance.spriteNameForSku)
          .toSet();
      expect(distinctSprites.length, CozySpriteCache.visualBudget);
    });
  });
}
