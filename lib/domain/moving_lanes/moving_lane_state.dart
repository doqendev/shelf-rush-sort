import '../game/board_state.dart';
import 'moving_lane_def.dart';

enum GrabInvalidReason { laneEmpty, alreadyHoldingProduct, productExpired }

final class LaneHeldProduct {
  const LaneHeldProduct({required this.laneId, required this.product});

  final String laneId;
  final ProductInstance product;
}

final class MovingLaneState {
  const MovingLaneState({
    required this.def,
    this.queueIndex = 0,
    this.elapsedInProduct = Duration.zero,
    this.heldProduct,
    this.missedCount = 0,
    this.grabbedCount = 0,
  });

  final MovingLaneDef def;
  final int queueIndex;
  final Duration elapsedInProduct;
  final LaneHeldProduct? heldProduct;
  final int missedCount;
  final int grabbedCount;

  MovingLaneProductDef? get currentProductDef {
    if (def.queue.isEmpty) {
      return null;
    }
    if (def.behavior == LaneBehavior.finite && queueIndex >= def.queue.length) {
      return null;
    }
    return def.queue[queueIndex % def.queue.length];
  }

  double get currentProgress {
    final MovingLaneProductDef? product = currentProductDef;
    if (product == null) {
      return 1;
    }
    return (elapsedInProduct.inMilliseconds / product.travelTimeMs).clamp(0, 1);
  }

  MovingLaneState copyWith({
    int? queueIndex,
    Duration? elapsedInProduct,
    LaneHeldProduct? heldProduct,
    bool clearHeldProduct = false,
    int? missedCount,
    int? grabbedCount,
  }) {
    return MovingLaneState(
      def: def,
      queueIndex: queueIndex ?? this.queueIndex,
      elapsedInProduct: elapsedInProduct ?? this.elapsedInProduct,
      heldProduct: clearHeldProduct ? null : heldProduct ?? this.heldProduct,
      missedCount: missedCount ?? this.missedCount,
      grabbedCount: grabbedCount ?? this.grabbedCount,
    );
  }
}

final class GrabValidation {
  const GrabValidation.valid() : invalidReason = null;

  const GrabValidation.invalid(this.invalidReason);

  final GrabInvalidReason? invalidReason;

  bool get isValid => invalidReason == null;
}

final class GrabLaneProductResult {
  const GrabLaneProductResult({required this.state, this.invalidReason});

  final MovingLaneState state;
  final GrabInvalidReason? invalidReason;

  bool get isValid => invalidReason == null;
}
