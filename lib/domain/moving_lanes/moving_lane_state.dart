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
    this.speedMultiplier = 1,
    this.slowRemaining = Duration.zero,
    this.exhausted = false,
    this.lastMissedSkuId,
  });

  final MovingLaneDef def;
  final int queueIndex;
  final Duration elapsedInProduct;
  final LaneHeldProduct? heldProduct;
  final int missedCount;
  final int grabbedCount;
  final double speedMultiplier;
  final Duration slowRemaining;
  final bool exhausted;
  final String? lastMissedSkuId;

  MovingLaneProductDef? get currentProductDef {
    if (def.queue.isEmpty || exhausted) {
      return null;
    }
    if (def.behavior == LaneBehavior.finite &&
        !def.loopsMissedProducts &&
        queueIndex >= def.queue.length) {
      return null;
    }
    return def.queue[queueIndex % def.queue.length];
  }

  double get currentProgress {
    final MovingLaneProductDef? product = currentProductDef;
    if (product == null) {
      return 1;
    }
    final double laneSpeed = def.speedCellsPerSecond <= 0
        ? 1
        : def.speedCellsPerSecond;
    final double slowMultiplier = speedMultiplier <= 0 ? 1 : speedMultiplier;
    final int effectiveTravelMs =
        (product.travelTimeMs / laneSpeed / slowMultiplier).round().clamp(
          1,
          product.travelTimeMs * 10,
        );
    return (elapsedInProduct.inMilliseconds / effectiveTravelMs).clamp(0, 1);
  }

  bool get slowConveyorActive => slowRemaining > Duration.zero;

  String get stableHash {
    return <Object?>[
      def.id,
      queueIndex,
      elapsedInProduct.inMilliseconds,
      heldProduct?.product.id,
      heldProduct?.product.skuId,
      missedCount,
      grabbedCount,
      speedMultiplier.toStringAsFixed(2),
      slowRemaining.inMilliseconds,
      exhausted,
    ].join('|');
  }

  List<MovingLaneProductDef> visibleProductWindow() {
    final int requested = def.visibleWindowCells.round().clamp(1, 5);
    final List<MovingLaneProductDef> products = <MovingLaneProductDef>[];
    for (var offset = 0; offset < requested; offset += 1) {
      final int index = queueIndex + offset;
      if (def.queue.isEmpty) {
        break;
      }
      if (def.behavior == LaneBehavior.finite &&
          !def.loopsMissedProducts &&
          index >= def.queue.length) {
        break;
      }
      products.add(def.queue[index % def.queue.length]);
    }
    return products;
  }

  MovingLaneState copyWith({
    int? queueIndex,
    Duration? elapsedInProduct,
    LaneHeldProduct? heldProduct,
    bool clearHeldProduct = false,
    int? missedCount,
    int? grabbedCount,
    double? speedMultiplier,
    Duration? slowRemaining,
    bool? exhausted,
    String? lastMissedSkuId,
    bool clearLastMissedSkuId = false,
  }) {
    return MovingLaneState(
      def: def,
      queueIndex: queueIndex ?? this.queueIndex,
      elapsedInProduct: elapsedInProduct ?? this.elapsedInProduct,
      heldProduct: clearHeldProduct ? null : heldProduct ?? this.heldProduct,
      missedCount: missedCount ?? this.missedCount,
      grabbedCount: grabbedCount ?? this.grabbedCount,
      speedMultiplier: speedMultiplier ?? this.speedMultiplier,
      slowRemaining: slowRemaining ?? this.slowRemaining,
      exhausted: exhausted ?? this.exhausted,
      lastMissedSkuId: clearLastMissedSkuId
          ? null
          : lastMissedSkuId ?? this.lastMissedSkuId,
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
