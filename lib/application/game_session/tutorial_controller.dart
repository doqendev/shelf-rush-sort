import '../../domain/core/value_objects.dart';

final class TutorialMoveHint {
  const TutorialMoveHint({required this.source, required this.target});

  final CellAddress source;
  final CellAddress target;
}

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

  bool allowsSelection(
    CellAddress address, {
    required int levelNumber,
    required int moveCount,
  }) {
    final TutorialMoveHint? hint = _activeHint(levelNumber, moveCount);
    return hint == null || address == hint.source;
  }

  bool allowsPlacement(
    CellAddress address, {
    required int levelNumber,
    required int moveCount,
  }) {
    final TutorialMoveHint? hint = _activeHint(levelNumber, moveCount);
    return hint == null || address == hint.target;
  }

  bool allowsCell(CellAddress address, int levelNumber, {int moveCount = 0}) {
    final TutorialMoveHint? hint = _activeHint(levelNumber, moveCount);
    if (hint == null) {
      return true;
    }
    return address == hint.source || address == hint.target;
  }

  TutorialMoveHint? _activeHint(int levelNumber, int moveCount) {
    if (moveCount > 0) {
      return null;
    }
    return hintForLevel(levelNumber);
  }
}
