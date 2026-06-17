import '../core/value_objects.dart';

enum InvalidMoveReason {
  levelEnded,
  sameCell,
  sameCompartmentNotAllowed,
  missingSource,
  missingTarget,
  sourceEmpty,
  sourceBlocked,
  targetOccupied,
  targetBlocked,
  targetLocked,
  sourceLocked,
  productNotSelectable,
  laneProductExpired,
  restrictedByTutorial,
}

enum MoveQuality {
  completesTriple,
  createsPair,
  revealEnabling,
  laneSave,
  reserveSafe,
  riskyReserve,
  neutral,
  badButLegal,
}

final class MoveAction {
  const MoveAction({required this.source, required this.target});

  final CellAddress source;
  final CellAddress target;
}

final class PlaceProductAction {
  const PlaceProductAction({required this.skuId, required this.target});

  final SkuId skuId;
  final CellAddress target;
}

final class MoveValidation {
  const MoveValidation.valid() : invalidReason = null;

  const MoveValidation.invalid(this.invalidReason);

  final InvalidMoveReason? invalidReason;

  bool get isValid => invalidReason == null;
}

final class LegalMove {
  const LegalMove({required this.source, required this.target});

  final CellAddress source;
  final CellAddress target;
}
