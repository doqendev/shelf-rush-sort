import '../game/board_state.dart';
import 'moving_lane_def.dart';
import 'moving_lane_state.dart';

final class MovingLaneRules {
  const MovingLaneRules();

  MovingLaneState tickLane(MovingLaneState state, Duration delta) {
    final MovingLaneProductDef? current = state.currentProductDef;
    final Duration slowRemaining = _nextSlowRemaining(state, delta);
    final double speedMultiplier = slowRemaining > Duration.zero
        ? state.speedMultiplier
        : 1;
    if (current == null || delta <= Duration.zero) {
      return state.copyWith(
        speedMultiplier: speedMultiplier,
        slowRemaining: slowRemaining,
        clearLastMissedSkuId: true,
      );
    }
    var elapsed = state.elapsedInProduct + delta;
    var queueIndex = state.queueIndex;
    var missedCount = state.missedCount;
    var exhausted = state.exhausted;
    String? lastMissedSkuId;
    var activeProduct = current;

    while (true) {
      final int travelMs = _effectiveTravelMs(activeProduct, state.def, state);
      if (elapsed.inMilliseconds < travelMs) {
        break;
      }
      elapsed -= Duration(milliseconds: travelMs);
      lastMissedSkuId = activeProduct.skuId;
      missedCount += 1;
      queueIndex += 1;
      final bool maxMissesReached =
          state.def.maxMisses != null && missedCount >= state.def.maxMisses!;
      final bool finiteQueueEnded =
          state.def.behavior == LaneBehavior.finite &&
          !state.def.loopsMissedProducts &&
          queueIndex >= state.def.queue.length;
      exhausted = maxMissesReached || finiteQueueEnded;
      if (exhausted) {
        elapsed = Duration.zero;
        break;
      }
      activeProduct = state.def.queue[queueIndex % state.def.queue.length];
    }
    return state.copyWith(
      queueIndex: queueIndex,
      elapsedInProduct: elapsed,
      missedCount: missedCount,
      speedMultiplier: speedMultiplier,
      slowRemaining: slowRemaining,
      exhausted: exhausted,
      lastMissedSkuId: lastMissedSkuId,
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

  MovingLaneState applySlowConveyor(
    MovingLaneState state, {
    Duration duration = const Duration(seconds: 10),
    double speedMultiplier = 0.5,
  }) {
    return state.copyWith(
      speedMultiplier: speedMultiplier.clamp(0.1, 1).toDouble(),
      slowRemaining: duration,
    );
  }

  int _effectiveTravelMs(
    MovingLaneProductDef product,
    MovingLaneDef lane,
    MovingLaneState state,
  ) {
    final double laneSpeed = lane.speedCellsPerSecond <= 0
        ? 1
        : lane.speedCellsPerSecond;
    final double slowMultiplier = state.speedMultiplier <= 0
        ? 1
        : state.speedMultiplier;
    return (product.travelTimeMs / laneSpeed / slowMultiplier)
        .round()
        .clamp(1, product.travelTimeMs * 10)
        .toInt();
  }

  Duration _nextSlowRemaining(MovingLaneState state, Duration delta) {
    if (state.slowRemaining <= Duration.zero || delta <= Duration.zero) {
      return state.slowRemaining;
    }
    final Duration remaining = state.slowRemaining - delta;
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
