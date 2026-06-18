import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../../domain/blockers/blocker_def.dart';
import '../../../domain/content/product_def.dart';
import 'product_renderer.dart';

final class DraggedProductComponent extends PositionComponent {
  DraggedProductComponent({
    required this.productDef,
    required this.cellBlocker,
    required this.productBlocker,
    required super.position,
    required super.size,
  }) {
    priority = 1000;
  }

  final ProductDef productDef;
  final BlockerKind cellBlocker;
  final BlockerKind productBlocker;

  @override
  void render(Canvas canvas) {
    ProductRenderer.render(
      canvas,
      size.toRect(),
      productDef: productDef,
      selected: true,
      cellBlocker: cellBlocker,
      productBlocker: productBlocker,
      opacity: 0.94,
    );
  }
}
