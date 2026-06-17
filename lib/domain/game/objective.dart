import '../core/value_objects.dart';
import 'board_state.dart';
import 'resolution.dart';

enum ObjectiveType { clearAll, clearSkuTargets }

final class ObjectiveRequirement {
  ObjectiveRequirement({
    required this.type,
    Map<SkuId, int> targetCounts = const <SkuId, int>{},
  }) : targetCounts = Map<SkuId, int>.unmodifiable(targetCounts);

  final ObjectiveType type;
  final Map<SkuId, int> targetCounts;
}

final class ObjectiveState {
  ObjectiveState({
    required this.requirement,
    required this.initialVisibleProducts,
    Map<SkuId, int>? remainingTargets,
    this.clearedProducts = 0,
  }) : remainingTargets = Map<SkuId, int>.unmodifiable(
         remainingTargets ?? requirement.targetCounts,
       );

  final ObjectiveRequirement requirement;
  final int initialVisibleProducts;
  final Map<SkuId, int> remainingTargets;
  final int clearedProducts;

  bool isComplete(BoardState board) {
    switch (requirement.type) {
      case ObjectiveType.clearAll:
        final bool hiddenEmpty = board.compartments.every(
          (CompartmentState compartment) => !compartment.hasHiddenProducts,
        );
        return board.visibleProductCount == 0 && hiddenEmpty;
      case ObjectiveType.clearSkuTargets:
        return remainingTargets.values.every((int count) => count <= 0);
    }
  }

  ObjectiveState copyWith({
    Map<SkuId, int>? remainingTargets,
    int? clearedProducts,
  }) {
    return ObjectiveState(
      requirement: requirement,
      initialVisibleProducts: initialVisibleProducts,
      remainingTargets: remainingTargets ?? this.remainingTargets,
      clearedProducts: clearedProducts ?? this.clearedProducts,
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
    for (final ClearedTriple triple in result.clearedTriples) {
      clearedCount += triple.products.length;
      if (remaining.containsKey(triple.skuId)) {
        remaining[triple.skuId] =
            (remaining[triple.skuId] ?? 0) - triple.products.length;
      }
    }
    return objective.copyWith(
      remainingTargets: remaining,
      clearedProducts: clearedCount,
    );
  }
}
