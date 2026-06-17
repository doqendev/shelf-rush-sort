enum BoosterKind {
  hint,
  shuffle,
  hammer,
  freezeTime,
  extraShelf,
  revealHidden,
  slowConveyor,
}

final class BoosterDef {
  const BoosterDef({
    required this.kind,
    required this.priceCoins,
    required this.startsUnlockedAtLevel,
  });

  final BoosterKind kind;
  final int priceCoins;
  final int startsUnlockedAtLevel;
}
