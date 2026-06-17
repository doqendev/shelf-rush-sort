import '../blockers/blocker_def.dart';
import '../blockers/blocker_rules.dart';
import '../core/value_objects.dart';
import 'board_state.dart';
import 'fail_reason.dart';
import 'move.dart';
import 'resolution.dart';

final class BoardRules {
  const BoardRules({this.allowSameCompartmentMoves = true});

  final bool allowSameCompartmentMoves;
  static const BlockerRules _blockerRules = BlockerRules();

  MoveValidation validateMove(BoardState state, MoveAction move) {
    if (state.levelEnded) {
      return const MoveValidation.invalid(InvalidMoveReason.levelEnded);
    }
    if (move.source == move.target) {
      return const MoveValidation.invalid(InvalidMoveReason.sameCell);
    }
    if (!allowSameCompartmentMoves &&
        move.source.compartmentIndex == move.target.compartmentIndex) {
      return const MoveValidation.invalid(
        InvalidMoveReason.sameCompartmentNotAllowed,
      );
    }

    final ShelfCell? sourceCell = state.cellAt(move.source);
    if (sourceCell == null) {
      return const MoveValidation.invalid(InvalidMoveReason.missingSource);
    }
    final ShelfCell? targetCell = state.cellAt(move.target);
    if (targetCell == null) {
      return const MoveValidation.invalid(InvalidMoveReason.missingTarget);
    }

    final CompartmentState sourceCompartment = state.compartmentAtAddress(
      move.source,
    );
    final CompartmentState targetCompartment = state.compartmentAtAddress(
      move.target,
    );
    if (!sourceCompartment.interactable) {
      return const MoveValidation.invalid(InvalidMoveReason.sourceLocked);
    }
    if (!targetCompartment.interactable) {
      return const MoveValidation.invalid(InvalidMoveReason.targetLocked);
    }
    if (sourceCell.product == null) {
      return const MoveValidation.invalid(InvalidMoveReason.sourceEmpty);
    }
    if (_blockerRules.blocksSelection(sourceCell.blocker) ||
        _blockerRules.blocksSelection(sourceCell.product!.blocker)) {
      return const MoveValidation.invalid(InvalidMoveReason.sourceBlocked);
    }
    if (!sourceCell.product!.selectable) {
      return const MoveValidation.invalid(
        InvalidMoveReason.productNotSelectable,
      );
    }
    if (targetCell.product != null) {
      return const MoveValidation.invalid(InvalidMoveReason.targetOccupied);
    }
    if (_blockerRules.blocksPlacement(targetCell.blocker)) {
      return const MoveValidation.invalid(InvalidMoveReason.targetBlocked);
    }
    return const MoveValidation.valid();
  }

  MoveValidation validatePlacement(BoardState state, CellAddress target) {
    if (state.levelEnded) {
      return const MoveValidation.invalid(InvalidMoveReason.levelEnded);
    }
    final ShelfCell? targetCell = state.cellAt(target);
    if (targetCell == null) {
      return const MoveValidation.invalid(InvalidMoveReason.missingTarget);
    }
    final CompartmentState targetCompartment = state.compartmentAtAddress(
      target,
    );
    if (!targetCompartment.interactable) {
      return const MoveValidation.invalid(InvalidMoveReason.targetLocked);
    }
    if (targetCell.product != null) {
      return const MoveValidation.invalid(InvalidMoveReason.targetOccupied);
    }
    if (_blockerRules.blocksPlacement(targetCell.blocker)) {
      return const MoveValidation.invalid(InvalidMoveReason.targetBlocked);
    }
    return const MoveValidation.valid();
  }

  ResolutionResult applyMove(BoardState state, MoveAction move) {
    final MoveValidation validation = validateMove(state, move);
    final InvalidMoveReason? invalidReason = validation.invalidReason;
    if (invalidReason != null) {
      return ResolutionResult.invalid(state, invalidReason);
    }

    final ProductInstance product = state.productAt(move.source)!;
    final BoardState updated = state
        .replaceCell(move.source, state.cellAt(move.source)!.withoutProduct())
        .replaceCell(
          move.target,
          state.cellAt(move.target)!.withProduct(product),
        );
    return resolveBoard(updated, moveApplied: true);
  }

  ResolutionResult placeProduct(
    BoardState state, {
    required ProductInstance product,
    required CellAddress target,
  }) {
    final MoveValidation validation = validatePlacement(state, target);
    final InvalidMoveReason? invalidReason = validation.invalidReason;
    if (invalidReason != null) {
      return ResolutionResult.invalid(state, invalidReason);
    }
    final BoardState updated = state.replaceCell(
      target,
      state.cellAt(target)!.withProduct(product),
    );
    return resolveBoard(updated, moveApplied: true);
  }

  ResolutionResult resolveBoard(
    BoardState state, {
    bool moveApplied = false,
    LevelEnd? levelEnd,
  }) {
    BoardState current = state;
    final List<ClearedTriple> cleared = <ClearedTriple>[];
    final List<RevealedProduct> revealed = <RevealedProduct>[];
    var combo = 0;
    var changed = true;

    while (changed) {
      changed = false;
      for (var index = 0; index < current.compartments.length; index += 1) {
        final CompartmentState compartment = current.compartments[index];
        if (!_isClearable(compartment)) {
          continue;
        }

        final SkuId skuId = compartment.frontCells.first.product!.skuId;
        final List<ProductInstance> products = compartment.frontCells
            .map((ShelfCell cell) => cell.product!)
            .toList(growable: false);
        cleared.add(
          ClearedTriple(
            compartmentIndex: compartment.index,
            skuId: skuId,
            products: products,
          ),
        );

        final List<ProductInstance> hidden = List<ProductInstance>.of(
          compartment.hiddenStack,
        );
        final List<ShelfCell> replacementCells = List<ShelfCell>.generate(
          cellsPerCompartment,
          (int cellIndex) {
            if (hidden.isEmpty) {
              return const ShelfCell.empty();
            }
            final ProductInstance product = hidden.removeAt(0);
            final CellAddress address = compartment.addressForCell(cellIndex);
            revealed.add(RevealedProduct(address: address, product: product));
            return ShelfCell(product: product);
          },
          growable: false,
        );

        current = current.replaceCompartment(
          compartment.copyWith(
            frontCells: replacementCells,
            hiddenStack: hidden,
            clearedCount: compartment.clearedCount + 1,
          ),
        );
        combo += 1;
        changed = true;
        break;
      }
    }

    return ResolutionResult(
      state: current,
      moveApplied: moveApplied,
      clearedTriples: cleared,
      revealedProducts: revealed,
      comboCount: combo,
      levelEnd: levelEnd,
    );
  }

  List<LegalMove> generateLegalMoves(BoardState state) {
    final List<CellAddress> sources = <CellAddress>[];
    final List<CellAddress> targets = <CellAddress>[];
    for (final CompartmentState compartment in state.compartments) {
      if (!compartment.interactable) {
        continue;
      }
      for (var cell = 0; cell < cellsPerCompartment; cell += 1) {
        final CellAddress address = compartment.addressForCell(cell);
        final ShelfCell shelfCell = compartment.cellAt(cell);
        if (shelfCell.product != null &&
            !_blockerRules.blocksSelection(shelfCell.blocker) &&
            !_blockerRules.blocksSelection(shelfCell.product!.blocker)) {
          sources.add(address);
        }
        if (shelfCell.product == null &&
            !_blockerRules.blocksPlacement(shelfCell.blocker)) {
          targets.add(address);
        }
      }
    }
    final List<LegalMove> moves = <LegalMove>[];
    for (final CellAddress source in sources) {
      for (final CellAddress target in targets) {
        final MoveAction move = MoveAction(source: source, target: target);
        if (validateMove(state, move).isValid) {
          moves.add(LegalMove(source: source, target: target));
        }
      }
    }
    return moves;
  }

  bool wouldComplete(BoardState state, SkuId skuId, CellAddress target) {
    final CompartmentState compartment = state.compartmentAtAddress(target);
    final List<ShelfCell> occupied = compartment.frontCells
        .where((ShelfCell cell) => cell.product != null)
        .toList(growable: false);
    if (occupied.length != cellsPerCompartment - 1) {
      return false;
    }
    return occupied.every((ShelfCell cell) => cell.product!.skuId == skuId);
  }

  LevelEnd? evaluateLevelEnd(BoardState state) {
    if (state.visibleProductCount == 0) {
      return const LevelEnd.won();
    }
    if (state.emptyInteractableCellCount == 0 &&
        generateLegalMoves(state).isEmpty) {
      return const LevelEnd.failed(LevelFailReason.boardJammed);
    }
    return null;
  }

  bool _isClearable(CompartmentState compartment) {
    if (!compartment.interactable) {
      return false;
    }
    if (compartment.frontCells.any((ShelfCell cell) {
      return cell.product == null ||
          cell.blocker != BlockerKind.none ||
          cell.product!.blocker != BlockerKind.none;
    })) {
      return false;
    }
    final SkuId skuId = compartment.frontCells.first.product!.skuId;
    return compartment.frontCells.every(
      (ShelfCell cell) => cell.product!.skuId == skuId,
    );
  }
}
