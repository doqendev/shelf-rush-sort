import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/domain/moving_lanes/moving_lane_def.dart';
import 'package:shelf_rush_sort/domain/moving_lanes/moving_lane_rules.dart';
import 'package:shelf_rush_sort/domain/moving_lanes/moving_lane_state.dart';

void main() {
  test(
    'moving lane advances deterministically and can grab current product',
    () {
      final MovingLaneState state = MovingLaneState(
        def: MovingLaneDef(
          id: 'lane',
          orientation: LaneOrientation.horizontal,
          behavior: LaneBehavior.finite,
          speedCellsPerSecond: 1,
          queue: const <MovingLaneProductDef>[
            MovingLaneProductDef(skuId: 'sku_a', travelTimeMs: 1000),
            MovingLaneProductDef(skuId: 'sku_b', travelTimeMs: 1000),
          ],
        ),
      );
      const MovingLaneRules rules = MovingLaneRules();

      final MovingLaneState ticked = rules.tickLane(
        state,
        const Duration(milliseconds: 1000),
      );
      expect(ticked.queueIndex, 1);
      expect(ticked.missedCount, 1);

      final grab = rules.grabProduct(ticked);
      expect(grab.isValid, isTrue);
      expect(grab.state.heldProduct!.product.skuId, 'sku_b');
    },
  );
}
