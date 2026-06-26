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

/// Whether a rewarded revive can meaningfully rescue this failure. A watched ad
/// must materially fix the failure cause, so we never offer or run a revive we
/// cannot honour (second-pass audit P1.5). Timer/move-limit/jam failures have
/// concrete rescues; lane/blocker/objective failures do not yet, so no revive
/// is offered for them.
bool canReviveFrom(LevelFailReason reason) {
  return switch (reason) {
    LevelFailReason.timerExpired ||
    LevelFailReason.moveLimitExceeded ||
    LevelFailReason.boardJammed ||
    LevelFailReason.noUsefulMoves ||
    LevelFailReason.reserveMismanaged => true,
    LevelFailReason.laneExhausted ||
    LevelFailReason.blockerRemaining ||
    LevelFailReason.objectiveImpossible ||
    LevelFailReason.none => false,
  };
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
