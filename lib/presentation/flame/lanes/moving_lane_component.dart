import 'dart:ui';

import 'package:flame/components.dart';

import '../../../domain/content/product_def.dart';
import '../../../domain/moving_lanes/moving_lane_def.dart';
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

  MovingLaneState lane;
  final ProductCatalog productCatalog;
  final InputRouter inputRouter;

  @override
  Future<void> onLoad() async {
    await _buildChildren();
  }

  @override
  void render(Canvas canvas) {}

  Future<void> syncLane(MovingLaneState next) async {
    if (lane.stableHash == next.stableHash &&
        lane.currentProgress == next.currentProgress) {
      return;
    }
    lane = next;
    removeAll(children.toList());
    await _buildChildren();
  }

  Future<void> _buildChildren() async {
    await add(
      LanePathComponent(
        orientation: lane.def.orientation,
        progress: lane.currentProgress,
        slowed: lane.slowConveyorActive,
        exhausted: lane.exhausted,
        position: Vector2.zero(),
        size: size,
      ),
    );
    if (lane.heldProduct != null || lane.exhausted) {
      return;
    }
    final List<MovingLaneProductDef> visible = lane.visibleProductWindow();
    if (visible.isEmpty) {
      return;
    }
    final bool horizontal = lane.def.orientation == LaneOrientation.horizontal;
    final double slotExtent = horizontal
        ? (size.x - 22) / visible.length
        : (size.y - 22) / visible.length;
    for (var index = 0; index < visible.length; index += 1) {
      final ProductDef? productDef = productCatalog.bySku(visible[index].skuId);
      if (productDef == null) {
        continue;
      }
      final double progressOffset = index == 0 ? lane.currentProgress * 12 : 0;
      final Vector2 childPosition = horizontal
          ? Vector2(10 + index * slotExtent + progressOffset, 8)
          : Vector2(8, 10 + index * slotExtent + progressOffset);
      final Vector2 childSize = horizontal
          ? Vector2((slotExtent - 8).clamp(34, 50).toDouble(), size.y - 16)
          : Vector2(size.x - 16, (slotExtent - 8).clamp(34, 50).toDouble());
      await add(
        LaneProductComponent(
          laneId: lane.def.id,
          productDef: productDef,
          inputRouter: inputRouter,
          position: childPosition,
          size: childSize,
        ),
      );
    }
  }
}
