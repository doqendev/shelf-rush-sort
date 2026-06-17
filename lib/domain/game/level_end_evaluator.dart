import '../content/level_def.dart';
import '../core/value_objects.dart';
import '../moving_lanes/moving_lane_state.dart';
import 'board_rules.dart';
import 'board_state.dart';
import 'fail_reason.dart';
import 'objective.dart';
import 'timer.dart';

final class LevelEndEvaluator {
  const LevelEndEvaluator();

  LevelEnd? evaluate({
    required BoardState board,
    required ObjectiveState objective,
    required LevelTimer timer,
    required List<MovingLaneState> lanes,
    required LevelDef level,
    required BoardRules boardRules,
    required int moveCount,
  }) {
    if (objective.isComplete(board)) {
      return const LevelEnd.won();
    }
    if (timer.expired) {
      return const LevelEnd.failed(LevelFailReason.timerExpired);
    }
    final int? moveLimit = level.moveLimit;
    if (moveLimit != null && moveCount >= moveLimit) {
      return const LevelEnd.failed(LevelFailReason.moveLimitExceeded);
    }
    if (_requiredLaneExhausted(lanes)) {
      return const LevelEnd.failed(LevelFailReason.laneExhausted);
    }
    if (_objectiveImpossible(board, objective, lanes)) {
      return const LevelEnd.failed(LevelFailReason.objectiveImpossible);
    }
    final legalMoves = boardRules.generateLegalMoves(board);
    if (legalMoves.isEmpty) {
      if (_hasBlockedRemainingProducts(board)) {
        return const LevelEnd.failed(LevelFailReason.blockerRemaining);
      }
      return const LevelEnd.failed(LevelFailReason.boardJammed);
    }
    if (!boardRules.hasUsefulMove(board) &&
        !_laneCanCreateProgress(board, lanes, boardRules)) {
      return const LevelEnd.failed(LevelFailReason.noUsefulMoves);
    }
    return null;
  }

  bool _requiredLaneExhausted(List<MovingLaneState> lanes) {
    for (final MovingLaneState lane in lanes) {
      if (lane.def.requiredForObjective && lane.exhausted) {
        return true;
      }
    }
    return false;
  }

  bool _objectiveImpossible(
    BoardState board,
    ObjectiveState objective,
    List<MovingLaneState> lanes,
  ) {
    if (objective.requirement.type != ObjectiveType.clearSkuTargets) {
      return false;
    }
    final Map<SkuId, int> available = <SkuId, int>{};
    for (final ProductInstance product in board.visibleProducts) {
      available[product.skuId] = (available[product.skuId] ?? 0) + 1;
    }
    for (final CompartmentState compartment in board.compartments) {
      for (final ProductInstance product in compartment.hiddenStack) {
        available[product.skuId] = (available[product.skuId] ?? 0) + 1;
      }
    }
    for (final MovingLaneState lane in lanes) {
      if (lane.exhausted) {
        continue;
      }
      for (final product in lane.visibleProductWindow()) {
        available[product.skuId] = (available[product.skuId] ?? 0) + 1;
      }
      final ProductInstance? held = lane.heldProduct?.product;
      if (held != null) {
        available[held.skuId] = (available[held.skuId] ?? 0) + 1;
      }
    }
    for (final MapEntry<SkuId, int> entry
        in objective.remainingTargets.entries) {
      if (entry.value > (available[entry.key] ?? 0)) {
        return true;
      }
    }
    return false;
  }

  bool _laneCanCreateProgress(
    BoardState board,
    List<MovingLaneState> lanes,
    BoardRules boardRules,
  ) {
    for (final MovingLaneState lane in lanes) {
      if (lane.exhausted) {
        continue;
      }
      for (final product in lane.visibleProductWindow()) {
        for (final CompartmentState compartment in board.compartments) {
          if (!compartment.interactable) {
            continue;
          }
          for (var cell = 0; cell < cellsPerCompartment; cell += 1) {
            final CellAddress target = compartment.addressForCell(cell);
            if (board.cellAt(target)?.product != null) {
              continue;
            }
            if (boardRules.wouldComplete(board, product.skuId, target)) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  bool _hasBlockedRemainingProducts(BoardState board) {
    for (final CompartmentState compartment in board.compartments) {
      for (final ShelfCell cell in compartment.frontCells) {
        if (cell.product != null &&
            (cell.isBlocked || cell.product!.isBlocked)) {
          return true;
        }
      }
    }
    return false;
  }
}
