import 'dart:ui';

import 'package:flame/components.dart';

import '../../../domain/content/product_def.dart';
import '../../../domain/moving_lanes/moving_lane_state.dart';
import '../input/input_router.dart';
import 'lane_path_component.dart';
import 'lane_product_component.dart';

final class MovingLaneComponent extends PositionComponent {
  MovingLaneComponent({
    required this.lane,
    required this.productCatalog,
    required this.inputRouter,
    required super.position,
    required super.size,
  });

  final MovingLaneState lane;
  final ProductCatalog productCatalog;
  final InputRouter inputRouter;

  @override
  Future<void> onLoad() async {
    await add(LanePathComponent(position: Vector2.zero(), size: size));
    final current = lane.currentProductDef;
    if (current == null || lane.heldProduct != null) {
      return;
    }
    final ProductDef? productDef = productCatalog.bySku(current.skuId);
    if (productDef == null) {
      return;
    }
    final double travelWidth = size.x - 48;
    final double x = 12 + travelWidth * lane.currentProgress;
    await add(
      LaneProductComponent(
        laneId: lane.def.id,
        productDef: productDef,
        inputRouter: inputRouter,
        position: Vector2(x, 8),
        size: Vector2(42, size.y - 16),
      ),
    );
  }

  @override
  void render(Canvas canvas) {}
}
