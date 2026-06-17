import 'dart:convert';
import 'dart:io';

import 'package:shelf_rush_sort/domain/content/product_def.dart';

Future<void> main(List<String> args) async {
  final String outputPath = args.isEmpty
      ? 'build/reports/product_readability_review.html'
      : args.single;
  final ProductCatalog catalog = ProductCatalog.fromJson(
    jsonDecode(
          await File('assets/data/bundled/product_catalog.json').readAsString(),
        )
        as Map<String, Object?>,
  );
  final File output = File(outputPath);
  await output.parent.create(recursive: true);
  await output.writeAsString(_renderHtml(catalog));
  stdout.writeln('Wrote $outputPath for ${catalog.products.length} products.');
}

String _renderHtml(ProductCatalog catalog) {
  final Map<String, List<ProductDef>> byFamily = <String, List<ProductDef>>{};
  for (final ProductDef product in catalog.products) {
    byFamily.putIfAbsent(product.family, () => <ProductDef>[]).add(product);
  }
  return '''
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Shelf Rush Sort Product Readability Review</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 24px; color: #1f2a32; background: #f7f3e8; }
    h1 { margin: 0 0 8px; }
    .meta { margin-bottom: 24px; color: #4d5b63; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 14px; }
    .card { background: white; border: 1px solid #d8d1c3; border-radius: 8px; padding: 14px; }
    .row { display: flex; gap: 10px; align-items: end; flex-wrap: wrap; }
    .chip { display: inline-block; padding: 3px 7px; border: 1px solid #ccd4d8; border-radius: 999px; font-size: 12px; margin: 2px; }
    .shelf { width: 138px; height: 62px; background: #e9dcc9; border: 2px solid #8b6a4b; border-radius: 6px; display: flex; align-items: center; justify-content: center; }
    .product { display: inline-flex; align-items: center; justify-content: center; color: white; font-weight: 800; text-shadow: 0 1px 2px #0008; border: 2px solid #2e4450; margin: 3px; }
    .box { border-radius: 7px; }
    .bottle, .can, .jar { border-radius: 18px; }
    .pouch, .produce { border-radius: 22px; }
    .family { margin: 28px 0 12px; }
    .manual { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; margin-top: 10px; font-size: 12px; color: #52616a; }
    .manual div { border-top: 1px solid #e0e5e8; padding-top: 6px; }
  </style>
</head>
<body>
  <h1>Product Readability Review</h1>
  <div class="meta">Generated from bundled product metadata. Review at 32, 44, 64, and 96 px plus shelf-cell context.</div>
  ${byFamily.entries.map(_renderFamily).join('\n')}
</body>
</html>
''';
}

String _renderFamily(MapEntry<String, List<ProductDef>> entry) {
  return '''
  <h2 class="family">${_escape(entry.key)}</h2>
  <div class="grid">
    ${entry.value.map(_renderProduct).join('\n')}
  </div>
''';
}

String _renderProduct(ProductDef product) {
  final String initials = product.displayName
      .split(' ')
      .where((String part) => part.isNotEmpty)
      .map((String part) => part.substring(0, 1))
      .take(2)
      .join();
  final String swatches = <int>[32, 44, 64, 96].map((int size) {
    return '<span class="product ${product.shape.name}" style="width:${size}px;height:${size}px;background:${product.colorHex};font-size:${(size * 0.32).round()}px">$initials</span>';
  }).join();
  return '''
    <section class="card">
      <strong>${_escape(product.displayName)}</strong>
      <div>${_escape(product.skuId)} | ${_escape(product.shape.name)} | ${_escape(product.colorHex)}</div>
      <div class="row">$swatches</div>
      <div class="shelf"><span class="product ${product.shape.name}" style="width:44px;height:44px;background:${product.colorHex};font-size:14px">$initials</span></div>
      <div>${product.readabilityTags.map((String tag) => '<span class="chip">${_escape(tag)}</span>').join()}</div>
      <div class="manual">
        <div>32 px pass/fail</div>
        <div>Colorblind pass/fail</div>
        <div>Similar SKU risk</div>
      </div>
    </section>
''';
}

String _escape(String value) {
  return const HtmlEscape().convert(value);
}
