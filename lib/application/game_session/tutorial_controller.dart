import '../../domain/core/value_objects.dart';

final class TutorialMoveHint {
  const TutorialMoveHint({required this.source, required this.target});

  final CellAddress source;
  final CellAddress target;
}

/// Drives the guided first level. The opening level's very first move is
/// restricted to a single demonstrated move (source -> target) so a cold player
/// is taught the rule with one guaranteed success; every move after it plays
/// freely (second-pass audit P0.5).
final class TutorialController {
  const TutorialController();

  TutorialMoveHint? hintForLevel(int levelNumber) {
    if (levelNumber != 1) {
      return null;
    }
    return TutorialMoveHint(
      source: CellAddress.fromCompartmentIndex(1, 0),
      target: CellAddress.fromCompartmentIndex(0, 2),
    );
  }

  /// The single move the player is currently guided to make, or null when input
  /// is unrestricted. Only the very first move of level 1 is guided.
  TutorialMoveHint? guidedStep({
    required int levelNumber,
    required int moveCount,
  }) {
    if (levelNumber == 1 && moveCount == 0) {
      return hintForLevel(levelNumber);
    }
    return null;
  }

  bool allowsSelection(
    CellAddress address, {
    required int levelNumber,
    required int moveCount,
  }) {
    final TutorialMoveHint? step = guidedStep(
      levelNumber: levelNumber,
      moveCount: moveCount,
    );
    return step == null || address == step.source;
  }

  bool allowsPlacement(
    CellAddress address, {
    required int levelNumber,
    required int moveCount,
  }) {
    final TutorialMoveHint? step = guidedStep(
      levelNumber: levelNumber,
      moveCount: moveCount,
    );
    return step == null || address == step.target;
  }

  bool allowsCell(CellAddress address, int levelNumber, {int moveCount = 0}) {
    final TutorialMoveHint? step = guidedStep(
      levelNumber: levelNumber,
      moveCount: moveCount,
    );
    return step == null || address == step.source || address == step.target;
  }
}
