import '../game/board_state.dart';
import '../game/board_rules.dart';
import 'booster_def.dart';

final class BoosterUseResult {
  const BoosterUseResult({
    required this.board,
    required this.used,
    this.message,
  });

  final BoardState board;
  final bool used;
  final String? message;
}

final class BoosterRules {
  const BoosterRules({this.boardRules = const BoardRules()});

  final BoardRules boardRules;

  BoosterUseResult useBooster(BoardState board, BoosterKind booster) {
    switch (booster) {
      case BoosterKind.hint:
        final bool hasMove = boardRules.generateLegalMoves(board).isNotEmpty;
        return BoosterUseResult(
          board: board,
          used: hasMove,
          message: hasMove ? 'hint_available' : 'no_hint_available',
        );
      case BoosterKind.hammer:
      case BoosterKind.shuffle:
      case BoosterKind.freezeTime:
      case BoosterKind.extraShelf:
      case BoosterKind.revealHidden:
      case BoosterKind.slowConveyor:
        return BoosterUseResult(
          board: board,
          used: true,
          message: booster.name,
        );
    }
  }
}
