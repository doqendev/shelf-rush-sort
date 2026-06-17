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

  test('slow conveyor reduces effective lane progress', () {
    final MovingLaneState state = MovingLaneState(
      def: MovingLaneDef(
        id: 'lane',
        orientation: LaneOrientation.horizontal,
        behavior: LaneBehavior.finite,
        speedCellsPerSecond: 1,
        queue: const <MovingLaneProductDef>[
          MovingLaneProductDef(skuId: 'sku_a', travelTimeMs: 1000),
        ],
      ),
    );
    const MovingLaneRules rules = MovingLaneRules();

    final MovingLaneState slowed = rules.applySlowConveyor(state);
    final MovingLaneState ticked = rules.tickLane(
      slowed,
      const Duration(milliseconds: 1000),
    );

    expect(ticked.queueIndex, 0);
    expect(ticked.currentProgress, closeTo(0.5, 0.01));
    expect(ticked.slowConveyorActive, isTrue);
  });

  test('finite required lane records exhaustion after miss', () {
    final MovingLaneState state = MovingLaneState(
      def: MovingLaneDef(
        id: 'lane',
        orientation: LaneOrientation.horizontal,
        behavior: LaneBehavior.finite,
        speedCellsPerSecond: 1,
        requiredForObjective: true,
        queue: const <MovingLaneProductDef>[
          MovingLaneProductDef(skuId: 'sku_a', travelTimeMs: 1000),
        ],
      ),
    );

    final MovingLaneState ticked = const MovingLaneRules().tickLane(
      state,
      const Duration(milliseconds: 1000),
    );

    expect(ticked.exhausted, isTrue);
    expect(ticked.missedCount, 1);
    expect(ticked.lastMissedSkuId, 'sku_a');
  });
}
