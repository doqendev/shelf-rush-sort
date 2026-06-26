import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/domain/content/cozy_product_visuals.dart';

/// P0.1 — each SKU has ONE stable product visual (the same on the board, in
/// previews, and on the collection screen), drawn from the cozy product set.
void main() {
  test('every mapped SKU resolves to a known product, stably', () {
    for (final MapEntry<String, String> entry in kSkuProductVisual.entries) {
      expect(kCozyProducts, contains(entry.value));
      // Stable: the same SKU always resolves to the same product.
      expect(productVisualForSku(entry.key), entry.value);
      expect(productVisualForSku(entry.key), entry.value);
    }
  });

  test('unknown SKUs fall back deterministically to a known product', () {
    final String first = productVisualForSku('sku_unknown_999');
    final String second = productVisualForSku('sku_unknown_999');
    expect(kCozyProducts, contains(first));
    expect(first, second);
  });
}
