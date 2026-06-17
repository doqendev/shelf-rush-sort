import 'package:flutter/material.dart';

import '../../../application/game_session/game_session_state.dart';
import '../../../domain/game/fail_reason.dart';

final class LossPanel extends StatelessWidget {
  const LossPanel({
    super.key,
    required this.session,
    required this.onRetry,
    required this.onRevive,
  });

  final GameSessionState session;
  final VoidCallback onRetry;
  final VoidCallback onRevive;

  @override
  Widget build(BuildContext context) {
    final _LossCopy copy = _copyForReason(session.failReason);
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0x66000000),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Icon(copy.icon, size: 42),
                    const SizedBox(height: 10),
                    Text(
                      copy.title,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(copy.body, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: onRevive,
                      icon: const Icon(Icons.play_circle_outline),
                      label: Text(copy.rescueLabel),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _LossCopy _copyForReason(LevelFailReason reason) {
    return switch (reason) {
      LevelFailReason.timerExpired => const _LossCopy(
        Icons.timer_off,
        'Time ran out',
        'Freeze time or clear faster before the shelf timer expires.',
        'Add time',
      ),
      LevelFailReason.laneExhausted => const _LossCopy(
        Icons.view_stream,
        'Lane item missed',
        'A required conveyor item left the lane before it was sorted.',
        'Replay lane',
      ),
      LevelFailReason.noUsefulMoves => const _LossCopy(
        Icons.psychology_alt,
        'No useful moves',
        'The remaining moves cannot create a clear or rescue path.',
        'Use rescue',
      ),
      LevelFailReason.moveLimitExceeded => const _LossCopy(
        Icons.swap_horiz,
        'Move limit reached',
        'The order needed fewer shelf moves.',
        'Try extra shelf',
      ),
      LevelFailReason.objectiveImpossible => const _LossCopy(
        Icons.assignment_late,
        'Order impossible',
        'A required target is no longer available in the board or lanes.',
        'Retry order',
      ),
      LevelFailReason.blockerRemaining => const _LossCopy(
        Icons.lock,
        'Shelf blocked',
        'A blocker is still preventing the final sort.',
        'Use hammer',
      ),
      LevelFailReason.reserveMismanaged ||
      LevelFailReason.boardJammed ||
      LevelFailReason.none => const _LossCopy(
        Icons.inventory_2,
        'Shelf jammed',
        'The board has no clean rescue path left.',
        'Revive',
      ),
    };
  }
}

final class _LossCopy {
  const _LossCopy(this.icon, this.title, this.body, this.rescueLabel);

  final IconData icon;
  final String title;
  final String body;
  final String rescueLabel;
}
