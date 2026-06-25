import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import '../../../domain/blockers/blocker_def.dart';
import '../../../domain/content/product_def.dart';
import 'product_renderer.dart';

/// The floating product while dragging. It lifts (scales up and rises above the
/// finger) on grab, and on an invalid drop springs back to its source shelf,
/// lowering as it travels.
final class DraggedProductComponent extends PositionComponent {
  DraggedProductComponent({
    required this.productDef,
    required this.cellBlocker,
    required this.productBlocker,
    required super.position,
    required super.size,
    this.reduceMotion = false,
  }) {
    priority = 1000;
    if (reduceMotion) {
      _lift = 1;
    }
  }

  final ProductDef productDef;
  final BlockerKind cellBlocker;
  final BlockerKind productBlocker;
  final bool reduceMotion;

  double _lift = 0;
  bool _returning = false;

  /// Springs the lifted product back to [target] (its source shelf origin),
  /// then invokes [onComplete]. Skips straight to [onComplete] under reduced
  /// motion.
  void animateReturnTo(Vector2 target, {required void Function() onComplete}) {
    if (reduceMotion) {
      onComplete();
      return;
    }
    _returning = true;
    add(
      MoveToEffect(
        target,
        EffectController(duration: 0.2, curve: Curves.easeOutBack),
        onComplete: onComplete,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_returning) {
      _lift = (_lift - dt / 0.2).clamp(0.0, 1.0);
    } else if (_lift < 1) {
      _lift = (_lift + dt / 0.09).clamp(0.0, 1.0);
    }
  }

  @override
  void render(Canvas canvas) {
    final Rect rect = size.toRect();
    final double cx = rect.center.dx;
    final double cy = rect.center.dy;
    canvas.save();
    canvas.translate(cx, cy);
    final double scale = 1 + 0.12 * _lift;
    canvas.scale(scale, scale);
    canvas.translate(-cx, -cy - 18 * _lift);
    ProductRenderer.render(
      canvas,
      rect,
      productDef: productDef,
      selected: true,
      cellBlocker: cellBlocker,
      productBlocker: productBlocker,
      opacity: 0.96,
    );
    canvas.restore();
  }
}
