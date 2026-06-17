import '../content/level_def.dart';
import '../core/value_objects.dart';
import '../game/board_rules.dart';
import '../game/board_state.dart';
import '../game/move.dart';
import '../moving_lanes/moving_lane_rules.dart';
import '../moving_lanes/moving_lane_state.dart';
import 'validation_report.dart';

final class BotSimulator {
  const BotSimulator({
    this.boardRules = const BoardRules(allowSameCompartmentMoves: false),
    this.laneRules = const MovingLaneRules(),
  });

  final BoardRules boardRules;
  final MovingLaneRules laneRules;

  SolverResult solve(LevelDef level, {int maxMoves = 250}) {
    var board = boardRules.resolveBoard(level.createBoardState()).state;
    final List<MovingLaneState> lanes = level.movingLanes
        .map((lane) => MovingLaneState(def: lane))
        .toList(growable: false);
    var moves = 0;

    while (moves < maxMoves && board.visibleProductCount > 0) {
      final _LanePlacement? lanePlacement = _findLanePlacement(board, lanes);
      if (lanePlacement != null) {
        final result = boardRules.placeProduct(
          board,
          product: lanePlacement.product,
          target: lanePlacement.target,
        );
        board = result.state;
        moves += 1;
        continue;
      }

      final MoveAction? completingMove = _findCompletingMove(board);
      if (completingMove == null) {
        return SolverResult(
          solved: false,
          moves: moves,
          reason: 'no_completing_move',
        );
      }
      final result = boardRules.applyMove(board, completingMove);
      if (!result.isValid) {
        return SolverResult(
          solved: false,
          moves: moves,
          reason: result.invalidReason?.name,
        );
      }
      board = result.state;
      moves += 1;
    }

    return SolverResult(
      solved: board.visibleProductCount == 0,
      moves: moves,
      reason: board.visibleProductCount == 0 ? null : 'move_budget_exhausted',
    );
  }

  MoveAction? _findCompletingMove(BoardState board) {
    for (final LegalMove move in boardRules.generateLegalMoves(board)) {
      final String skuId = board.productAt(move.source)!.skuId;
      if (boardRules.wouldComplete(board, skuId, move.target)) {
        return MoveAction(source: move.source, target: move.target);
      }
    }
    return null;
  }

  _LanePlacement? _findLanePlacement(
    BoardState board,
    List<MovingLaneState> lanes,
  ) {
    for (final MovingLaneState lane in lanes) {
      if (lane.def.queue.isEmpty) {
        continue;
      }
      for (var offset = 0; offset < lane.def.queue.length; offset += 1) {
        final productDef =
            lane.def.queue[(lane.queueIndex + offset) % lane.def.queue.length];
        final String skuId = productDef.skuId;
        for (final compartment in board.compartments) {
          if (!compartment.interactable) {
            continue;
          }
          for (var cell = 0; cell < compartment.frontCells.length; cell += 1) {
            final target = compartment.addressForCell(cell);
            if (board.cellAt(target)!.product == null &&
                boardRules.wouldComplete(board, skuId, target)) {
              return _LanePlacement(
                product: ProductInstance(
                  id: '${lane.def.id}_solver_${lane.queueIndex}_$offset',
                  skuId: skuId,
                ),
                target: target,
              );
            }
          }
        }
      }
    }
    return null;
  }
}

final class _LanePlacement {
  const _LanePlacement({required this.product, required this.target});

  final ProductInstance product;
  final CellAddress target;
}
