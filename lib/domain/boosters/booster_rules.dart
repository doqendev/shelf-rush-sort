import '../blockers/blocker_def.dart';
import '../content/level_def.dart';
import '../core/seeded_random.dart';
import '../core/value_objects.dart';
import '../game/board_rules.dart';
import '../game/board_state.dart';
import '../game/move.dart';
import '../game/objective.dart';
import '../game/resolution.dart';
import '../game/timer.dart';
import '../moving_lanes/moving_lane_rules.dart';
import '../moving_lanes/moving_lane_state.dart';
import 'booster_def.dart';

final class BoosterAvailability {
  const BoosterAvailability.available() : reason = null;

  const BoosterAvailability.unavailable(this.reason);

  final String? reason;

  bool get canUse => reason == null;
}

final class BoosterContext {
  BoosterContext({
    required this.board,
    required this.objective,
    required this.timer,
    required List<MovingLaneState> lanes,
    required this.selectedCell,
    required this.seed,
    required this.level,
  }) : lanes = List<MovingLaneState>.unmodifiable(lanes);

  final BoardState board;
  final ObjectiveState objective;
  final LevelTimer timer;
  final List<MovingLaneState> lanes;
  final CellAddress? selectedCell;
  final int seed;
  final LevelDef level;
}

final class BoosterUseResult {
  BoosterUseResult({
    required this.board,
    required this.objective,
    required this.timer,
    required List<MovingLaneState> lanes,
    required this.used,
    required this.reason,
    this.suggestedMove,
    this.resolution,
    Map<String, Object?> replayPayload = const <String, Object?>{},
  }) : lanes = List<MovingLaneState>.unmodifiable(lanes),
       replayPayload = Map<String, Object?>.unmodifiable(replayPayload);

  factory BoosterUseResult.invalid(BoosterContext context, String reason) {
    return BoosterUseResult(
      board: context.board,
      objective: context.objective,
      timer: context.timer,
      lanes: context.lanes,
      used: false,
      reason: reason,
    );
  }

  final BoardState board;
  final ObjectiveState objective;
  final LevelTimer timer;
  final List<MovingLaneState> lanes;
  final bool used;
  final String reason;
  final LegalMove? suggestedMove;
  final ResolutionResult? resolution;
  final Map<String, Object?> replayPayload;
}

sealed class BoosterCommand {
  const BoosterCommand({
    required this.kind,
    this.boardRules = const BoardRules(),
    this.objectiveRules = const ObjectiveRules(),
    this.laneRules = const MovingLaneRules(),
  });

  final BoosterKind kind;
  final BoardRules boardRules;
  final ObjectiveRules objectiveRules;
  final MovingLaneRules laneRules;

  BoosterAvailability canUse(BoosterContext context);

  BoosterUseResult apply(BoosterContext context);

  BoosterUseResult invalid(BoosterContext context, String reason) {
    return BoosterUseResult.invalid(context, reason);
  }
}

final class BoosterRules {
  const BoosterRules({
    this.boardRules = const BoardRules(),
    this.objectiveRules = const ObjectiveRules(),
    this.laneRules = const MovingLaneRules(),
  });

  final BoardRules boardRules;
  final ObjectiveRules objectiveRules;
  final MovingLaneRules laneRules;

  BoosterUseResult useBooster(BoosterContext context, BoosterKind booster) {
    final BoosterCommand command = switch (booster) {
      BoosterKind.hint => _HintCommand(boardRules: boardRules),
      BoosterKind.hammer => _HammerCommand(
        boardRules: boardRules,
        objectiveRules: objectiveRules,
      ),
      BoosterKind.shuffle => _ShuffleCommand(boardRules: boardRules),
      BoosterKind.freezeTime => _FreezeTimeCommand(),
      BoosterKind.extraShelf => _ExtraShelfCommand(boardRules: boardRules),
      BoosterKind.revealHidden => _RevealHiddenCommand(),
      BoosterKind.slowConveyor => _SlowConveyorCommand(laneRules: laneRules),
    };
    final BoosterAvailability availability = command.canUse(context);
    if (!availability.canUse) {
      return command.invalid(context, availability.reason!);
    }
    return command.apply(context);
  }
}

final class _HintCommand extends BoosterCommand {
  const _HintCommand({required super.boardRules})
    : super(kind: BoosterKind.hint);

  @override
  BoosterAvailability canUse(BoosterContext context) {
    return boardRules.generateLegalMoves(context.board).isEmpty
        ? const BoosterAvailability.unavailable('no_legal_hint')
        : const BoosterAvailability.available();
  }

  @override
  BoosterUseResult apply(BoosterContext context) {
    final List<LegalMove> legalMoves = boardRules.generateLegalMoves(
      context.board,
    );
    LegalMove? bestMove;
    var bestScore = -1;
    for (final LegalMove move in legalMoves) {
      final MoveQuality quality = boardRules.classifyMove(
        context.board,
        MoveAction(source: move.source, target: move.target),
      );
      final int score = _score(quality);
      if (score > bestScore) {
        bestMove = move;
        bestScore = score;
      }
    }
    if (bestMove == null) {
      return invalid(context, 'no_legal_hint');
    }
    return BoosterUseResult(
      board: context.board,
      objective: context.objective,
      timer: context.timer,
      lanes: context.lanes,
      used: true,
      reason: 'hint_selected',
      suggestedMove: bestMove,
      replayPayload: <String, Object?>{
        'source': bestMove.source.key,
        'target': bestMove.target.key,
      },
    );
  }

  int _score(MoveQuality quality) {
    return switch (quality) {
      MoveQuality.completesTriple => 100,
      MoveQuality.revealEnabling => 95,
      MoveQuality.laneSave => 90,
      MoveQuality.createsPair => 75,
      MoveQuality.reserveSafe => 45,
      MoveQuality.neutral => 10,
      MoveQuality.riskyReserve => 5,
      MoveQuality.badButLegal => 0,
    };
  }
}

final class _HammerCommand extends BoosterCommand {
  const _HammerCommand({
    required super.boardRules,
    required super.objectiveRules,
  }) : super(kind: BoosterKind.hammer);

  @override
  BoosterAvailability canUse(BoosterContext context) {
    final CellAddress? selected = context.selectedCell;
    if (selected == null) {
      return const BoosterAvailability.unavailable('hammer_needs_selection');
    }
    final ShelfCell? cell = context.board.cellAt(selected);
    if (cell == null) {
      return const BoosterAvailability.unavailable('hammer_invalid_cell');
    }
    if (cell.product == null && cell.blocker == BlockerKind.none) {
      return const BoosterAvailability.unavailable('hammer_empty_cell');
    }
    return const BoosterAvailability.available();
  }

  @override
  BoosterUseResult apply(BoosterContext context) {
    final CellAddress selected = context.selectedCell!;
    final ShelfCell cell = context.board.cellAt(selected)!;
    BoardState updated = context.board;
    ObjectiveState objective = context.objective;
    String reason;

    if (cell.blocker != BlockerKind.none) {
      updated = updated.replaceCell(
        selected,
        ShelfCell(product: cell.product, blocker: BlockerKind.none),
      );
      reason = 'hammer_removed_cell_blocker';
    } else if (cell.product?.blocker != null &&
        cell.product!.blocker != BlockerKind.none) {
      updated = updated.replaceCell(
        selected,
        cell.withProduct(cell.product!.copyWith(blocker: BlockerKind.none)),
      );
      reason = 'hammer_removed_product_blocker';
    } else {
      final ProductInstance product = cell.product!;
      updated = updated.replaceCell(selected, cell.withoutProduct());
      objective = objectiveRules.onProductRemoved(objective, product: product);
      reason = 'hammer_removed_product';
    }

    final ResolutionResult resolution = boardRules.resolveBoard(updated);
    objective = objectiveRules.onResolution(objective, resolution);
    return BoosterUseResult(
      board: resolution.state,
      objective: objective,
      timer: context.timer,
      lanes: context.lanes,
      used: true,
      reason: reason,
      resolution: resolution,
      replayPayload: <String, Object?>{'target': selected.key},
    );
  }
}

final class _ShuffleCommand extends BoosterCommand {
  const _ShuffleCommand({required super.boardRules})
    : super(kind: BoosterKind.shuffle);

  @override
  BoosterAvailability canUse(BoosterContext context) {
    return _movableProducts(context.board).length < 2
        ? const BoosterAvailability.unavailable('shuffle_needs_products')
        : const BoosterAvailability.available();
  }

  @override
  BoosterUseResult apply(BoosterContext context) {
    final List<_MovableProduct> movable = _movableProducts(context.board);
    final int beforeUseful = boardRules.usefulMoves(context.board).length;
    final String beforeHash = context.board.stableHash;
    for (var attempt = 0; attempt < 6; attempt += 1) {
      final BoardState shuffled = _shuffleOnce(context, movable, attempt);
      if (shuffled.stableHash == beforeHash) {
        continue;
      }
      final int afterUseful = boardRules.usefulMoves(shuffled).length;
      if (afterUseful >= beforeUseful) {
        final ResolutionResult resolution = boardRules.resolveBoard(shuffled);
        return BoosterUseResult(
          board: resolution.state,
          objective: context.objective,
          timer: context.timer,
          lanes: context.lanes,
          used: true,
          reason: 'shuffle_rearranged_products',
          resolution: resolution,
          replayPayload: <String, Object?>{'attempt': attempt},
        );
      }
    }
    return invalid(context, 'shuffle_would_not_improve');
  }

  List<_MovableProduct> _movableProducts(BoardState board) {
    final List<_MovableProduct> movable = <_MovableProduct>[];
    for (final CompartmentState compartment in board.compartments) {
      if (!compartment.interactable) {
        continue;
      }
      for (var cell = 0; cell < cellsPerCompartment; cell += 1) {
        final CellAddress address = compartment.addressForCell(cell);
        final ShelfCell shelfCell = compartment.cellAt(cell);
        final ProductInstance? product = shelfCell.product;
        if (product == null ||
            shelfCell.blocker != BlockerKind.none ||
            product.blocker != BlockerKind.none ||
            !product.selectable) {
          continue;
        }
        movable.add(_MovableProduct(address: address, product: product));
      }
    }
    return movable;
  }

  BoardState _shuffleOnce(
    BoosterContext context,
    List<_MovableProduct> movable,
    int attempt,
  ) {
    final List<ProductInstance> products = movable
        .map((_MovableProduct item) => item.product)
        .toList(growable: false);
    final SeededRandom random = SeededRandom(
      context.seed ^ context.board.stableHash.hashCode ^ attempt,
    );
    final List<ProductInstance> shuffled = List<ProductInstance>.of(products);
    for (var index = shuffled.length - 1; index > 0; index -= 1) {
      final int swap = random.nextInt(index + 1);
      final ProductInstance temp = shuffled[index];
      shuffled[index] = shuffled[swap];
      shuffled[swap] = temp;
    }
    if (_sameOrder(products, shuffled)) {
      shuffled.add(shuffled.removeAt(0));
    }
    var board = context.board;
    for (var index = 0; index < movable.length; index += 1) {
      final _MovableProduct target = movable[index];
      final ShelfCell cell = board.cellAt(target.address)!;
      board = board.replaceCell(
        target.address,
        cell.withProduct(shuffled[index]),
      );
    }
    return board;
  }

  bool _sameOrder(List<ProductInstance> left, List<ProductInstance> right) {
    for (var index = 0; index < left.length; index += 1) {
      if (left[index].id != right[index].id) {
        return false;
      }
    }
    return true;
  }
}

final class _FreezeTimeCommand extends BoosterCommand {
  const _FreezeTimeCommand() : super(kind: BoosterKind.freezeTime);

  @override
  BoosterAvailability canUse(BoosterContext context) {
    return context.timer.limit == null
        ? const BoosterAvailability.unavailable('freeze_needs_timer')
        : const BoosterAvailability.available();
  }

  @override
  BoosterUseResult apply(BoosterContext context) {
    final LevelTimer timer = context.timer.freeze(const Duration(seconds: 10));
    return BoosterUseResult(
      board: context.board,
      objective: context.objective,
      timer: timer,
      lanes: context.lanes,
      used: true,
      reason: 'timer_frozen',
      replayPayload: <String, Object?>{'duration_ms': 10000},
    );
  }
}

final class _ExtraShelfCommand extends BoosterCommand {
  const _ExtraShelfCommand({required super.boardRules})
    : super(kind: BoosterKind.extraShelf);

  @override
  BoosterAvailability canUse(BoosterContext context) {
    return _reservedCompartment(context.board) == null
        ? const BoosterAvailability.unavailable('extra_shelf_unavailable')
        : const BoosterAvailability.available();
  }

  @override
  BoosterUseResult apply(BoosterContext context) {
    final CompartmentState compartment = _reservedCompartment(context.board)!;
    final BoardState board = context.board.replaceCompartment(
      compartment.copyWith(locked: false),
    );
    return BoosterUseResult(
      board: board,
      objective: context.objective,
      timer: context.timer,
      lanes: context.lanes,
      used: true,
      reason: 'extra_shelf_unlocked',
      replayPayload: <String, Object?>{'compartment': compartment.index},
    );
  }

  CompartmentState? _reservedCompartment(BoardState board) {
    for (final CompartmentState compartment in board.compartments) {
      if (!compartment.locked || compartment.decorative) {
        continue;
      }
      final bool empty = compartment.frontCells.every(
        (ShelfCell cell) => cell.product == null,
      );
      if (empty && !compartment.hasHiddenProducts) {
        return compartment;
      }
    }
    return null;
  }
}

final class _RevealHiddenCommand extends BoosterCommand {
  const _RevealHiddenCommand() : super(kind: BoosterKind.revealHidden);

  @override
  BoosterAvailability canUse(BoosterContext context) {
    return _targetCompartments(context).isEmpty
        ? const BoosterAvailability.unavailable('no_hidden_to_reveal')
        : const BoosterAvailability.available();
  }

  @override
  BoosterUseResult apply(BoosterContext context) {
    var board = context.board;
    final List<CompartmentState> targets = _targetCompartments(context);
    for (final CompartmentState compartment in targets) {
      board = board.replaceCompartment(
        compartment.copyWith(hiddenPreviewRevealed: true),
      );
    }
    return BoosterUseResult(
      board: board,
      objective: context.objective.copyWith(
        hiddenRevealCount: context.objective.hiddenRevealCount + targets.length,
      ),
      timer: context.timer,
      lanes: context.lanes,
      used: true,
      reason: 'hidden_preview_revealed',
      replayPayload: <String, Object?>{
        'compartments': targets
            .map((CompartmentState compartment) => compartment.index)
            .toList(growable: false),
      },
    );
  }

  List<CompartmentState> _targetCompartments(BoosterContext context) {
    final CellAddress? selected = context.selectedCell;
    if (selected != null) {
      final CompartmentState compartment = context.board.compartmentAtAddress(
        selected,
      );
      if (compartment.hasHiddenProducts && !compartment.hiddenPreviewRevealed) {
        return <CompartmentState>[compartment];
      }
    }
    return context.board.compartments
        .where((CompartmentState compartment) {
          return compartment.hasHiddenProducts &&
              !compartment.hiddenPreviewRevealed;
        })
        .toList(growable: false);
  }
}

final class _SlowConveyorCommand extends BoosterCommand {
  const _SlowConveyorCommand({required super.laneRules})
    : super(kind: BoosterKind.slowConveyor);

  @override
  BoosterAvailability canUse(BoosterContext context) {
    return context.lanes.where((MovingLaneState lane) {
          return !lane.exhausted && lane.currentProductDef != null;
        }).isEmpty
        ? const BoosterAvailability.unavailable('no_active_conveyor')
        : const BoosterAvailability.available();
  }

  @override
  BoosterUseResult apply(BoosterContext context) {
    final List<MovingLaneState> lanes = context.lanes
        .map((MovingLaneState lane) {
          if (lane.exhausted || lane.currentProductDef == null) {
            return lane;
          }
          return laneRules.applySlowConveyor(lane);
        })
        .toList(growable: false);
    return BoosterUseResult(
      board: context.board,
      objective: context.objective,
      timer: context.timer,
      lanes: lanes,
      used: true,
      reason: 'conveyor_slowed',
      replayPayload: <String, Object?>{'duration_ms': 10000},
    );
  }
}

final class _MovableProduct {
  const _MovableProduct({required this.address, required this.product});

  final CellAddress address;
  final ProductInstance product;
}
