import '../core/value_objects.dart';
import 'board_state.dart';
import 'resolution.dart';

enum ObjectiveType {
  clearAll,
  clearSkuTargets,
  clearCategoryTargets,
  clearSpecialTargets,
  comboTarget,
  timeChallenge,
  laneDeliveryTarget,
}

final class ObjectiveRequirement {
  ObjectiveRequirement({
    required this.type,
    Map<SkuId, int> targetCounts = const <SkuId, int>{},
    Map<String, int> categoryTargets = const <String, int>{},
    Map<String, int> specialTargets = const <String, int>{},
    this.comboTarget = 0,
    this.laneDeliveryTarget = 0,
  }) : targetCounts = Map<SkuId, int>.unmodifiable(targetCounts),
       categoryTargets = Map<String, int>.unmodifiable(categoryTargets),
       specialTargets = Map<String, int>.unmodifiable(specialTargets);

  final ObjectiveType type;
  final Map<SkuId, int> targetCounts;
  final Map<String, int> categoryTargets;
  final Map<String, int> specialTargets;
  final int comboTarget;
  final int laneDeliveryTarget;
}

final class ObjectiveState {
  ObjectiveState({
    required this.requirement,
    required this.initialVisibleProducts,
    Map<SkuId, int>? remainingTargets,
    Map<String, int>? remainingCategoryTargets,
    Map<String, int>? remainingSpecialTargets,
    this.clearedProducts = 0,
    this.clearedTriples = 0,
    this.currentCombo = 0,
    this.maxCombo = 0,
    this.laneDeliveredProducts = 0,
    this.hiddenRevealCount = 0,
  }) : remainingTargets = Map<SkuId, int>.unmodifiable(
         remainingTargets ?? requirement.targetCounts,
       ),
       remainingCategoryTargets = Map<String, int>.unmodifiable(
         remainingCategoryTargets ?? requirement.categoryTargets,
       ),
       remainingSpecialTargets = Map<String, int>.unmodifiable(
         remainingSpecialTargets ?? requirement.specialTargets,
       );

  final ObjectiveRequirement requirement;
  final int initialVisibleProducts;
  final Map<SkuId, int> remainingTargets;
  final Map<String, int> remainingCategoryTargets;
  final Map<String, int> remainingSpecialTargets;
  final int clearedProducts;
  final int clearedTriples;
  final int currentCombo;
  final int maxCombo;
  final int laneDeliveredProducts;
  final int hiddenRevealCount;

  bool isComplete(BoardState board) {
    switch (requirement.type) {
      case ObjectiveType.clearAll:
        final bool hiddenEmpty = board.compartments.every(
          (CompartmentState compartment) => !compartment.hasHiddenProducts,
        );
        return board.visibleProductCount == 0 && hiddenEmpty;
      case ObjectiveType.clearSkuTargets:
        return remainingTargets.values.every((int count) => count <= 0);
      case ObjectiveType.clearCategoryTargets:
        return remainingCategoryTargets.values.every((int count) => count <= 0);
      case ObjectiveType.clearSpecialTargets:
        return remainingSpecialTargets.values.every((int count) => count <= 0);
      case ObjectiveType.comboTarget:
        return maxCombo >= requirement.comboTarget;
      case ObjectiveType.timeChallenge:
        return board.visibleProductCount == 0;
      case ObjectiveType.laneDeliveryTarget:
        return laneDeliveredProducts >= requirement.laneDeliveryTarget;
    }
  }

  ObjectiveState copyWith({
    Map<SkuId, int>? remainingTargets,
    Map<String, int>? remainingCategoryTargets,
    Map<String, int>? remainingSpecialTargets,
    int? clearedProducts,
    int? clearedTriples,
    int? currentCombo,
    int? maxCombo,
    int? laneDeliveredProducts,
    int? hiddenRevealCount,
  }) {
    return ObjectiveState(
      requirement: requirement,
      initialVisibleProducts: initialVisibleProducts,
      remainingTargets: remainingTargets ?? this.remainingTargets,
      remainingCategoryTargets:
          remainingCategoryTargets ?? this.remainingCategoryTargets,
      remainingSpecialTargets:
          remainingSpecialTargets ?? this.remainingSpecialTargets,
      clearedProducts: clearedProducts ?? this.clearedProducts,
      clearedTriples: clearedTriples ?? this.clearedTriples,
      currentCombo: currentCombo ?? this.currentCombo,
      maxCombo: maxCombo ?? this.maxCombo,
      laneDeliveredProducts:
          laneDeliveredProducts ?? this.laneDeliveredProducts,
      hiddenRevealCount: hiddenRevealCount ?? this.hiddenRevealCount,
    );
  }
}

final class ObjectiveRules {
  const ObjectiveRules();

  ObjectiveState initialState({
    required ObjectiveRequirement requirement,
    required BoardState board,
  }) {
    return ObjectiveState(
      requirement: requirement,
      initialVisibleProducts: board.visibleProductCount,
    );
  }

  ObjectiveState onResolution(
    ObjectiveState objective,
    ResolutionResult result,
  ) {
    if (result.clearedTriples.isEmpty) {
      return objective;
    }
    final Map<SkuId, int> remaining = Map<SkuId, int>.of(
      objective.remainingTargets,
    );
    var clearedCount = objective.clearedProducts;
    var clearedTriples = objective.clearedTriples;
    for (final ClearedTriple triple in result.clearedTriples) {
      clearedCount += triple.products.length;
      clearedTriples += 1;
      if (remaining.containsKey(triple.skuId)) {
        remaining[triple.skuId] =
            (remaining[triple.skuId] ?? 0) - triple.products.length;
      }
    }
    final int currentCombo = result.comboCount;
    final int maxCombo = currentCombo > objective.maxCombo
        ? currentCombo
        : objective.maxCombo;
    return objective.copyWith(
      remainingTargets: remaining,
      clearedProducts: clearedCount,
      clearedTriples: clearedTriples,
      currentCombo: currentCombo,
      maxCombo: maxCombo,
      hiddenRevealCount:
          objective.hiddenRevealCount + result.revealedProducts.length,
    );
  }

  ObjectiveState onProductRemoved(
    ObjectiveState objective, {
    required ProductInstance product,
  }) {
    final Map<SkuId, int> remaining = Map<SkuId, int>.of(
      objective.remainingTargets,
    );
    if (remaining.containsKey(product.skuId)) {
      remaining[product.skuId] = (remaining[product.skuId] ?? 0) - 1;
    }
    return objective.copyWith(
      remainingTargets: remaining,
      clearedProducts: objective.clearedProducts + 1,
    );
  }

  ObjectiveState onLaneDelivered(
    ObjectiveState objective, {
    required ProductInstance product,
  }) {
    final Map<SkuId, int> remaining = Map<SkuId, int>.of(
      objective.remainingTargets,
    );
    if (remaining.containsKey(product.skuId)) {
      remaining[product.skuId] = (remaining[product.skuId] ?? 0) - 1;
    }
    return objective.copyWith(
      remainingTargets: remaining,
      laneDeliveredProducts: objective.laneDeliveredProducts + 1,
    );
  }
}
