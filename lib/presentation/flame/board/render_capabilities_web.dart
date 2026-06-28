import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Whether the browser can GPU-blit product sprites.
///
/// Flutter web renders through CanvasKit; without WebGL it falls back to a
/// CPU rasterizer that draws shapes and text but cannot blit the product
/// sprite `drawImageRect` path, leaving the board with shadows but no products
/// (hands-on v4 P1.1). When this returns false, the sprite cache is bypassed so
/// every product draws as a colour-blob silhouette instead — never invisible.
///
/// Defaults to `true` on any detection error so a probing hiccup can never hide
/// good sprites on a perfectly capable device.
bool spritesRenderable() {
  try {
    final JSObject? document = globalContext['document'] as JSObject?;
    if (document == null) {
      return true;
    }
    final JSObject canvas = document.callMethod<JSObject>(
      'createElement'.toJS,
      'canvas'.toJS,
    );
    final JSAny? gl =
        canvas.callMethod<JSAny?>('getContext'.toJS, 'webgl'.toJS) ??
        canvas.callMethod<JSAny?>('getContext'.toJS, 'webgl2'.toJS);
    return gl != null;
  } catch (_) {
    return true;
  }
}
