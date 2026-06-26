import '../content/level_def.dart';

/// Awards 1–3 stars for completing a level based on move efficiency, so the win
/// screen reflects real performance instead of a fixed three (review section
/// 16.1 — "stars are not earned").
///
/// Par is a derived lower bound of one move per triple to clear (initial
/// product count / 3). Three stars at or below par, two within a half-par
/// slack, otherwise one for completing at all.
int starsForLevel({required int moveCount, required LevelDef level}) {
  final int par = _parForLevel(level);
  if (moveCount <= par) {
    return 3;
  }
  if (moveCount <= par + (par / 2).ceil()) {
    return 2;
  }
  return 1;
}

int _parForLevel(LevelDef level) {
  var products = 0;
  for (final CompartmentDef compartment in level.compartments) {
    products += compartment.cells.whereType<String>().length;
    products += compartment.hidden.length;
  }
  return (products / 3).ceil().clamp(1, 1 << 30);
}
