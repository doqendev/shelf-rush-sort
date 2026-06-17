import '../core/value_objects.dart';

enum ProductRenderMode { procedural, atlas }

final class ProductVisualDef {
  ProductVisualDef({
    required this.skuId,
    required this.renderMode,
    required this.shape,
    required this.colorHex,
    required List<String> silhouetteTags,
    this.atlasKey,
  }) : silhouetteTags = List<String>.unmodifiable(silhouetteTags);

  factory ProductVisualDef.fromJson(Map<String, Object?> json) {
    final List<Object?> tagJson = json['silhouetteTags']! as List<Object?>;
    return ProductVisualDef(
      skuId: json['skuId']! as String,
      renderMode: ProductRenderMode.values.byName(
        json['renderMode']! as String,
      ),
      shape: ProductShape.values.byName(json['shape']! as String),
      colorHex: json['colorHex']! as String,
      silhouetteTags: tagJson.cast<String>(),
      atlasKey: json['atlasKey'] as String?,
    );
  }

  final SkuId skuId;
  final ProductRenderMode renderMode;
  final ProductShape shape;
  final String colorHex;
  final List<String> silhouetteTags;
  final String? atlasKey;
}

final class ProductVisualManifest {
  ProductVisualManifest({
    required this.schemaVersion,
    required List<ProductVisualDef> productVisuals,
  }) : productVisuals = List<ProductVisualDef>.unmodifiable(productVisuals),
       _bySku = Map<SkuId, ProductVisualDef>.unmodifiable(
         <SkuId, ProductVisualDef>{
           for (final ProductVisualDef visual in productVisuals)
             visual.skuId: visual,
         },
       );

  factory ProductVisualManifest.fromJson(Map<String, Object?> json) {
    final List<Object?> visualsJson = json['productVisuals']! as List<Object?>;
    return ProductVisualManifest(
      schemaVersion: json['schemaVersion']! as int,
      productVisuals: visualsJson
          .map((Object? item) {
            return ProductVisualDef.fromJson(item! as Map<String, Object?>);
          })
          .toList(growable: false),
    );
  }

  final int schemaVersion;
  final List<ProductVisualDef> productVisuals;
  final Map<SkuId, ProductVisualDef> _bySku;

  ProductVisualDef? bySku(SkuId skuId) => _bySku[skuId];
}
