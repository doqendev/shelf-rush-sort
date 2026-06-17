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
    final BoardRules effectiveBoardRules = BoardRules(
      allowSameCompartmentMoves: level.rules.allowSameCompartmentMoves,
    );
    final SolverResult exact = _solveExact(
      level,
      effectiveBoardRules,
      maxDepth: 16,
    );
    if (exact.solved) {
      return exact;
    }
    var board = effectiveBoardRules
        .resolveBoard(level.createBoardState())
        .state;
    final List<MovingLaneState> lanes = level.movingLanes
        .map((lane) => MovingLaneState(def: lane))
        .toList(growable: false);
    var moves = 0;

    while (moves < maxMoves && board.visibleProductCount > 0) {
      final _LanePlacement? lanePlacement = _findLanePlacement(
        board,
        lanes,
        effectiveBoardRules,
      );
      if (lanePlacement != null) {
        final result = effectiveBoardRules.placeProduct(
          board,
          product: lanePlacement.product,
          target: lanePlacement.target,
        );
        board = result.state;
        moves += 1;
        continue;
      }

      final MoveAction? nextMove =
          _findCompletingMove(board, effectiveBoardRules) ??
          _findMoveByQuality(
            board,
            effectiveBoardRules,
            MoveQuality.createsPair,
          ) ??
          _findMoveByQuality(
            board,
            effectiveBoardRules,
            MoveQuality.reserveSafe,
          );
      if (nextMove == null) {
        return SolverResult(
          solved: false,
          moves: moves,
          reason: exact.reason ?? 'no_useful_move',
        );
      }
      final result = effectiveBoardRules.applyMove(board, nextMove);
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

  SolverResult _solveExact(
    LevelDef level,
    BoardRules effectiveBoardRules, {
    required int maxDepth,
  }) {
    final initial = effectiveBoardRules
        .resolveBoard(level.createBoardState())
        .state;
    if (initial.visibleProductCount > 12 || level.movingLanes.isNotEmpty) {
      return const SolverResult(
        solved: false,
        moves: 0,
        reason: 'exact_solver_skipped',
      );
    }
    final List<_SearchNode> queue = <_SearchNode>[
      _SearchNode(board: initial, depth: 0),
    ];
    final Set<String> seen = <String>{initial.stableHash};
    var cursor = 0;
    while (cursor < queue.length) {
      final _SearchNode node = queue[cursor];
      cursor += 1;
      if (node.board.visibleProductCount == 0) {
        return SolverResult(solved: true, moves: node.depth);
      }
      if (node.depth >= maxDepth) {
        continue;
      }
      final List<LegalMove> legalMoves = effectiveBoardRules.generateLegalMoves(
        node.board,
      );
      legalMoves.sort((LegalMove left, LegalMove right) {
        final int leftScore = _qualityScore(
          effectiveBoardRules.classifyMove(
            node.board,
            MoveAction(source: left.source, target: left.target),
          ),
        );
        final int rightScore = _qualityScore(
          effectiveBoardRules.classifyMove(
            node.board,
            MoveAction(source: right.source, target: right.target),
          ),
        );
        return rightScore.compareTo(leftScore);
      });
      for (final LegalMove move in legalMoves.take(60)) {
        final result = effectiveBoardRules.applyMove(
          node.board,
          MoveAction(source: move.source, target: move.target),
        );
        if (!result.isValid) {
          continue;
        }
        if (seen.add(result.state.stableHash)) {
          queue.add(_SearchNode(board: result.state, depth: node.depth + 1));
        }
      }
    }
    return const SolverResult(
      solved: false,
      moves: 0,
      reason: 'exact_solver_depth_exhausted',
    );
  }

  MoveAction? _findCompletingMove(BoardState board, BoardRules rules) {
    for (final LegalMove move in rules.generateLegalMoves(board)) {
      final String skuId = board.productAt(move.source)!.skuId;
      if (rules.wouldComplete(board, skuId, move.target)) {
        return MoveAction(source: move.source, target: move.target);
      }
    }
    return null;
  }

  MoveAction? _findMoveByQuality(
    BoardState board,
    BoardRules rules,
    MoveQuality quality,
  ) {
    for (final LegalMove move in rules.generateLegalMoves(board)) {
      final MoveAction action = MoveAction(
        source: move.source,
        target: move.target,
      );
      if (rules.classifyMove(board, action) == quality) {
        return action;
      }
    }
    return null;
  }

  _LanePlacement? _findLanePlacement(
    BoardState board,
    List<MovingLaneState> lanes,
    BoardRules rules,
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
                rules.wouldComplete(board, skuId, target)) {
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

  int _qualityScore(MoveQuality quality) {
    return switch (quality) {
      MoveQuality.completesTriple => 100,
      MoveQuality.revealEnabling => 90,
      MoveQuality.createsPair => 70,
      MoveQuality.reserveSafe => 40,
      MoveQuality.laneSave => 35,
      MoveQuality.neutral => 10,
      MoveQuality.riskyReserve => 4,
      MoveQuality.badButLegal => 0,
    };
  }
}

final class _SearchNode {
  const _SearchNode({required this.board, required this.depth});

  final BoardState board;
  final int depth;
}

final class _LanePlacement {
  const _LanePlacement({required this.product, required this.target});

  final ProductInstance product;
  final CellAddress target;
}
