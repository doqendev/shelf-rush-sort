import '../core/value_objects.dart';

final class ProductDef {
  const ProductDef({
    required this.skuId,
    required this.displayName,
    required this.family,
    required this.colorHex,
    required this.shape,
    required this.readabilityTags,
  });

  factory ProductDef.fromJson(Map<String, Object?> json) {
    final List<Object?> tagJson = json['readabilityTags']! as List<Object?>;
    return ProductDef(
      skuId: json['skuId']! as String,
      displayName: json['displayName']! as String,
      family: json['family']! as String,
      colorHex: json['colorHex']! as String,
      shape: ProductShape.values.byName(json['shape']! as String),
      readabilityTags: tagJson.cast<String>(),
    );
  }

  final SkuId skuId;
  final String displayName;
  final String family;
  final String colorHex;
  final ProductShape shape;
  final List<String> readabilityTags;
}

final class ProductCatalog {
  ProductCatalog({required List<ProductDef> products})
    : products = List<ProductDef>.unmodifiable(products),
      _bySku = Map<SkuId, ProductDef>.unmodifiable(<SkuId, ProductDef>{
        for (final ProductDef product in products) product.skuId: product,
      });

  factory ProductCatalog.fromJson(Map<String, Object?> json) {
    final List<Object?> productsJson = json['products']! as List<Object?>;
    return ProductCatalog(
      products: productsJson
          .map((Object? item) {
            return ProductDef.fromJson(item! as Map<String, Object?>);
          })
          .toList(growable: false),
    );
  }

  final List<ProductDef> products;
  final Map<SkuId, ProductDef> _bySku;

  ProductDef? bySku(SkuId skuId) => _bySku[skuId];

  bool containsSku(SkuId skuId) => _bySku.containsKey(skuId);
}
