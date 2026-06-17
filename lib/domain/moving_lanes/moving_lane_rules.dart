import '../game/board_state.dart';
import 'moving_lane_def.dart';
import 'moving_lane_state.dart';

final class MovingLaneRules {
  const MovingLaneRules();

  MovingLaneState tickLane(MovingLaneState state, Duration delta) {
    final MovingLaneProductDef? current = state.currentProductDef;
    if (current == null || delta <= Duration.zero) {
      return state;
    }
    final Duration elapsed = state.elapsedInProduct + delta;
    if (elapsed.inMilliseconds < current.travelTimeMs) {
      return state.copyWith(elapsedInProduct: elapsed);
    }
    return state.copyWith(
      queueIndex: state.queueIndex + 1,
      elapsedInProduct: Duration.zero,
      missedCount: state.missedCount + 1,
    );
  }

  GrabValidation validateGrab(MovingLaneState state) {
    if (state.heldProduct != null) {
      return const GrabValidation.invalid(
        GrabInvalidReason.alreadyHoldingProduct,
      );
    }
    if (state.currentProductDef == null) {
      return const GrabValidation.invalid(GrabInvalidReason.laneEmpty);
    }
    if (state.currentProgress >= 1) {
      return const GrabValidation.invalid(GrabInvalidReason.productExpired);
    }
    return const GrabValidation.valid();
  }

  GrabLaneProductResult grabProduct(MovingLaneState state) {
    final GrabValidation validation = validateGrab(state);
    final GrabInvalidReason? invalidReason = validation.invalidReason;
    if (invalidReason != null) {
      return GrabLaneProductResult(state: state, invalidReason: invalidReason);
    }
    final MovingLaneProductDef productDef = state.currentProductDef!;
    final ProductInstance product = ProductInstance(
      id: '${state.def.id}_${state.queueIndex}_${productDef.skuId}',
      skuId: productDef.skuId,
    );
    return GrabLaneProductResult(
      state: state.copyWith(
        queueIndex: state.queueIndex + 1,
        elapsedInProduct: Duration.zero,
        heldProduct: LaneHeldProduct(laneId: state.def.id, product: product),
        grabbedCount: state.grabbedCount + 1,
      ),
    );
  }

  MovingLaneState clearHeldProduct(MovingLaneState state) {
    return state.copyWith(clearHeldProduct: true);
  }
}
