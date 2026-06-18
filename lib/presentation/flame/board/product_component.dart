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
  });

  final CellAddress address;
  final ProductDef productDef;
  final InputRouter inputRouter;
  final bool selected;
  final BlockerKind cellBlocker;
  final BlockerKind productBlocker;
  Vector2? _lastDragCanvasPosition;

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
  void render(Canvas canvas) {
    ProductRenderer.render(
      canvas,
      size.toRect(),
      productDef: productDef,
      selected: selected,
      cellBlocker: cellBlocker,
      productBlocker: productBlocker,
    );
  }
}
