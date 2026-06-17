import '../core/value_objects.dart';
import 'board_state.dart';
import 'fail_reason.dart';
import 'move.dart';

final class ClearedTriple {
  ClearedTriple({
    required this.compartmentIndex,
    required this.skuId,
    required List<ProductInstance> products,
  }) : products = List<ProductInstance>.unmodifiable(products);

  final int compartmentIndex;
  final SkuId skuId;
  final List<ProductInstance> products;
}

final class RevealedProduct {
  const RevealedProduct({required this.address, required this.product});

  final CellAddress address;
  final ProductInstance product;
}

final class ResolutionResult {
  ResolutionResult({
    required this.state,
    this.moveApplied = false,
    this.invalidReason,
    List<ClearedTriple> clearedTriples = const <ClearedTriple>[],
    List<RevealedProduct> revealedProducts = const <RevealedProduct>[],
    this.comboCount = 0,
    this.levelEnd,
  }) : clearedTriples = List<ClearedTriple>.unmodifiable(clearedTriples),
       revealedProducts = List<RevealedProduct>.unmodifiable(revealedProducts);

  factory ResolutionResult.invalid(BoardState state, InvalidMoveReason reason) {
    return ResolutionResult(state: state, invalidReason: reason);
  }

  final BoardState state;
  final bool moveApplied;
  final InvalidMoveReason? invalidReason;
  final List<ClearedTriple> clearedTriples;
  final List<RevealedProduct> revealedProducts;
  final int comboCount;
  final LevelEnd? levelEnd;

  bool get isValid => invalidReason == null;
  bool get clearedAnything => clearedTriples.isNotEmpty;
}
