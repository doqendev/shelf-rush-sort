import '../blockers/blocker_def.dart';
import '../content/level_def.dart';

/// Awards 1–3 stars for completing a level (review section 16.1 — "stars are
/// not earned").
///
/// When the level carries authored thresholds ([LevelScore], intended to be
/// seeded from solver minimum moves — third-pass audit P1.7) those are used
/// directly. Otherwise a derived par heuristic is used that now also accounts
/// for blockers and objective-required lanes, not just the product count.
int starsForLevel({required int moveCount, required LevelDef level}) {
  final LevelScore? score = level.score;
  if (score != null) {
    if (moveCount <= score.threeStarMoves) {
      return 3;
    }
    if (moveCount <= score.twoStarMoves) {
      return 2;
    }
    return 1;
  }
  final int par = _parForLevel(level);
  if (moveCount <= par) {
    return 3;
  }
  if (moveCount <= par + (par / 2).ceil()) {
    return 2;
  }
  return 1;
}

/// Derived lower-bound par: one move per triple to clear, plus an extra move
/// for each blocker that must be removed and each lane the objective depends
/// on. Still a heuristic — authored [LevelScore] thresholds override it.
int _parForLevel(LevelDef level) {
  var products = 0;
  var blockers = 0;
  for (final CompartmentDef compartment in level.compartments) {
    products += compartment.cells.whereType<String>().length;
    products += compartment.hidden.length;
    blockers += compartment.cellBlockers
        .where((BlockerKind blocker) => blocker != BlockerKind.none)
        .length;
    blockers += compartment.productBlockers
        .where((BlockerKind blocker) => blocker != BlockerKind.none)
        .length;
  }
  final int laneLoad = level.movingLanes
      .where((lane) => lane.requiredForObjective)
      .length;
  return ((products / 3).ceil() + blockers + laneLoad).clamp(1, 1 << 30);
}
