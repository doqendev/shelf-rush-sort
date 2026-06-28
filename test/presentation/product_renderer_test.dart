import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/domain/blockers/blocker_def.dart';
import 'package:shelf_rush_sort/domain/content/product_def.dart';
import 'package:shelf_rush_sort/domain/core/value_objects.dart';
import 'package:shelf_rush_sort/presentation/flame/board/cozy_sprite_cache.dart';
import 'package:shelf_rush_sort/presentation/flame/board/product_renderer.dart';

/// Deterministic proof that the product layer actually rasterizes visible
/// pixels (hands-on v3 P0.1: in the reviewer's no-WebGL sandbox the rack drew
/// but product sprites did not, and he could not close product-art rendering).
/// This rasterizes a product through the real renderer and asserts the cell is
/// not visually empty — so a regression that makes products invisible fails CI
/// regardless of the GPU/CanvasKit path used to capture screenshots.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const ProductDef product = ProductDef(
    skuId: 'sku_000',
    displayName: 'Test Product',
    family: 'fruit',
    colorHex: 'E5484D',
    shape: ProductShape.produce,
    readabilityTags: <String>[],
  );

  // Fraction of the rasterized image whose pixels are not transparent.
  Future<double> paintedFraction(void Function(Canvas, Rect) paint) async {
    const int w = 140;
    const int h = 140;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    paint(canvas, Rect.fromLTWH(30, 20, 80, 100));
    final ui.Image image = await recorder.endRecording().toImage(w, h);
    final ByteData data = (await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!;
    final Uint8List bytes = data.buffer.asUint8List();
    int painted = 0;
    for (int i = 3; i < bytes.length; i += 4) {
      if (bytes[i] > 24) {
        painted += 1;
      }
    }
    return painted / (w * h);
  }

  test(
    'a product with no loaded sprite still draws a visible body (P0.1)',
    () async {
      final double covered = await paintedFraction((Canvas canvas, Rect rect) {
        ProductRenderer.render(
          canvas,
          rect,
          productDef: product,
          selected: false,
          cellBlocker: BlockerKind.none,
          productBlocker: BlockerKind.none,
        );
      });
      // The colour-blob fallback fills a large share of the cell; if the product
      // layer were ever blank (the v3 concern) this would be ~0.
      expect(
        covered,
        greaterThan(0.15),
        reason: 'product fallback must draw a visible body, not an empty cell',
      );
    },
  );

  test('a loaded product sprite rasterizes into the cell (P0.1)', () async {
    await CozySpriteCache.instance.ensureLoaded(Images());
    final double covered = await paintedFraction((Canvas canvas, Rect rect) {
      ProductRenderer.render(
        canvas,
        rect,
        productDef: product,
        selected: false,
        cellBlocker: BlockerKind.none,
        productBlocker: BlockerKind.none,
      );
    });
    expect(
      covered,
      greaterThan(0.08),
      reason: 'a loaded product sprite must rasterize visible pixels',
    );
  });

  test(
    'no-WebGL bypasses the sprite cache so products draw blobs (v4 P1.1)',
    () async {
      await CozySpriteCache.instance.ensureLoaded(Images());
      expect(
        CozySpriteCache.instance.imageForSku('sku_000'),
        isNotNull,
        reason: 'sanity: the sprite is available when renderable',
      );
      CozySpriteCache.instance.spritesRenderable = false;
      try {
        // With no WebGL the cache must report no image, so the renderer falls back
        // to the colour-blob path rather than drawing a blank product.
        expect(CozySpriteCache.instance.imageForSku('sku_000'), isNull);
        final double covered = await paintedFraction((
          Canvas canvas,
          Rect rect,
        ) {
          ProductRenderer.render(
            canvas,
            rect,
            productDef: product,
            selected: false,
            cellBlocker: BlockerKind.none,
            productBlocker: BlockerKind.none,
          );
        });
        expect(
          covered,
          greaterThan(0.15),
          reason: 'a no-WebGL product must still draw a visible body',
        );
      } finally {
        CozySpriteCache.instance.spritesRenderable = true;
      }
    },
  );
}
