import '../blockers/blocker_def.dart';
import '../blockers/blocker_rules.dart';
import '../core/value_objects.dart';
import 'board_state.dart';
import 'fail_reason.dart';
import 'hidden_preview.dart';
import 'move.dart';
import 'resolution.dart';

final class BoardRules {
  const BoardRules({this.allowSameCompartmentMoves = false});

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

    final ProductInstance sourceProduct = state.productAt(move.source)!;
    final ProductInstance product =
        sourceProduct.blocker == BlockerKind.mysteryBag
        ? sourceProduct.copyWith(blocker: BlockerKind.none)
        : sourceProduct;
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
        final List<HiddenPreviewLayerState> hiddenPreviewLayers =
            compartment.hiddenPreviewLayers.length <= 1
            ? const <HiddenPreviewLayerState>[]
            : compartment.hiddenPreviewLayers.sublist(1);
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
            hiddenPreviewLayers: hiddenPreviewLayers,
            hiddenPreviewRevealed:
                hiddenPreviewLayers.isNotEmpty &&
                hiddenPreviewLayers.first.previewMode ==
                    HiddenPreviewMode.exactDim,
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
            !_blockerRules.blocksSelection(shelfCell.product!.blocker) &&
            shelfCell.product!.selectable) {
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

  /// The best move to surface as a hint — the highest-quality legal move
  /// (prefers completing a triple, then a reveal, ... down to badButLegal).
  /// Null when there is no legal move. Shared by the hint booster and the
  /// idle-hint assist (hands-on v4 P1.3).
  LegalMove? bestHintMove(BoardState state) {
    LegalMove? best;
    var bestScore = -1;
    for (final LegalMove move in generateLegalMoves(state)) {
      final int score = _hintScore(
        classifyMove(
          state,
          MoveAction(source: move.source, target: move.target),
        ),
      );
      if (score > bestScore) {
        best = move;
        bestScore = score;
      }
    }
    return best;
  }

  static int _hintScore(MoveQuality quality) {
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

  MoveQuality classifyMove(BoardState state, MoveAction move) {
    final MoveValidation validation = validateMove(state, move);
    if (!validation.isValid) {
      return MoveQuality.badButLegal;
    }
    final ProductInstance product = state.productAt(move.source)!;
    if (wouldComplete(state, product.skuId, move.target)) {
      final CompartmentState target = state.compartmentAtAddress(move.target);
      return target.hasHiddenProducts
          ? MoveQuality.revealEnabling
          : MoveQuality.completesTriple;
    }
    if (_wouldCreatePair(state, product.skuId, move.target)) {
      return MoveQuality.createsPair;
    }
    final CompartmentState target = state.compartmentAtAddress(move.target);
    if (target.frontCells.every((ShelfCell cell) => cell.product == null)) {
      return MoveQuality.reserveSafe;
    }
    return MoveQuality.neutral;
  }

  bool hasUsefulMove(BoardState state) {
    for (final LegalMove move in generateLegalMoves(state)) {
      final MoveQuality quality = classifyMove(
        state,
        MoveAction(source: move.source, target: move.target),
      );
      if (quality == MoveQuality.completesTriple ||
          quality == MoveQuality.revealEnabling ||
          quality == MoveQuality.createsPair ||
          quality == MoveQuality.reserveSafe) {
        return true;
      }
    }
    return false;
  }

  List<LegalMove> usefulMoves(BoardState state) {
    return generateLegalMoves(state)
        .where((LegalMove move) {
          final MoveQuality quality = classifyMove(
            state,
            MoveAction(source: move.source, target: move.target),
          );
          return quality != MoveQuality.neutral &&
              quality != MoveQuality.riskyReserve &&
              quality != MoveQuality.badButLegal;
        })
        .toList(growable: false);
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

  bool _wouldCreatePair(BoardState state, SkuId skuId, CellAddress target) {
    final CompartmentState compartment = state.compartmentAtAddress(target);
    final int matching = compartment.frontCells.where((ShelfCell cell) {
      return cell.product?.skuId == skuId;
    }).length;
    return matching == 1;
  }
}
