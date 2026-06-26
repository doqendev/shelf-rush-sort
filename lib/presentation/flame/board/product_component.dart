import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

import '../../../domain/blockers/blocker_def.dart';
import '../../../domain/content/product_def.dart';
import '../../../domain/core/value_objects.dart';
import '../input/input_router.dart';
import 'product_renderer.dart';

final class ProductComponent extends PositionComponent
    with TapCallbacks, DragCallbacks {
  ProductComponent({
    required this.address,
    required this.productDef,
    required this.inputRouter,
    required this.selected,
    this.cellBlocker = BlockerKind.none,
    this.productBlocker = BlockerKind.none,
    required super.position,
    required super.size,
  }) {
    // Above the shelf scaffold (rack/targets at priority 0) but below hover
    // (50), drag (1000) and FX, so a retained product still renders correctly
    // after the scaffold is re-added on rebuild (second-pass audit M2).
    priority = 10;
  }

  /// Mutable so a retained component can be re-homed on a move instead of being
  /// destroyed and recreated (the move then animates — see ShelfWorld).
  CellAddress address;
  final ProductDef productDef;
  final InputRouter inputRouter;
  bool selected;
  BlockerKind cellBlocker;
  BlockerKind productBlocker;
  Vector2? _lastDragCanvasPosition;

  /// Fade level for the cozy sprite (0 = invisible). Hidden reveals enter at 0
  /// and ramp to 1 after the clear pop has played, so a reveal never overlaps
  /// the pop it replaces (hands-on audit P1.1 / Sprint C presentation order).
  double opacity = 1;
  double _revealDelay = 0;
  double _revealElapsed = 0;
  bool _revealing = false;
  static const double _revealFade = 0.22;

  /// True while this product is still fading in from a delayed reveal.
  bool get isRevealing => _revealing;

  /// Hold this product invisible for [delay] seconds, then fade it in — used
  /// for hidden products revealed by a clear so the reveal lands after the pop.
  void playRevealEntrance(double delay) {
    _revealDelay = delay;
    _revealElapsed = 0;
    _revealing = true;
    opacity = 0;
  }

  @override
  void onTapDown(TapDownEvent event) {
    inputRouter.onProductTapped(address);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _lastDragCanvasPosition = event.canvasPosition;
    inputRouter.onProductDragStart(address, event.canvasPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    _lastDragCanvasPosition = event.canvasEndPosition;
    inputRouter.onProductDragUpdate(event.canvasEndPosition);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    final Vector2? canvasPosition = _lastDragCanvasPosition;
    if (canvasPosition != null) {
      inputRouter.onProductDragEnd(canvasPosition);
    }
    _lastDragCanvasPosition = null;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_revealing) {
      return;
    }
    _revealElapsed += dt;
    final double local = _revealElapsed - _revealDelay;
    if (local <= 0) {
      opacity = 0;
      return;
    }
    opacity = (local / _revealFade).clamp(0.0, 1.0);
    if (opacity >= 1) {
      _revealing = false;
    }
  }

  @override
  void render(Canvas canvas) {
    ProductRenderer.render(
      canvas,
      size.toRect(),
      productDef: productDef,
      selected: selected,
      cellBlocker: cellBlocker,
      productBlocker: productBlocker,
      opacity: opacity,
    );
  }
}
