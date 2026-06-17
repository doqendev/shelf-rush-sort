enum LevelFailReason {
  none,
  timerExpired,
  boardJammed,
  noUsefulMoves,
  reserveMismanaged,
  laneExhausted,
  objectiveImpossible,
  moveLimitExceeded,
  blockerRemaining,
}

enum LevelEndType { won, failed }

final class LevelEnd {
  const LevelEnd.won()
    : type = LevelEndType.won,
      failReason = LevelFailReason.none;

  const LevelEnd.failed(this.failReason) : type = LevelEndType.failed;

  final LevelEndType type;
  final LevelFailReason failReason;

  bool get isWin => type == LevelEndType.won;
  bool get isFail => type == LevelEndType.failed;
}
