import 'package:flutter/material.dart';

import '../../../application/game_session/game_session_state.dart';
import '../../../domain/game/fail_reason.dart';
import '../../design/game_colors.dart';
import '../../design/game_surfaces.dart';
import '../../design/game_typography.dart';
import '../cozy/cozy_widgets.dart';

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
    final Color titleColor = session.failReason == LevelFailReason.timerExpired
        ? const Color(0xFFFFB3B3)
        : GameColors.sunny;
    return Positioned.fill(
      child: ColoredBox(
        color: GameColors.bezel.withValues(alpha: 0.62),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 36),
                    child: DecoratedBox(
                      decoration: GameSurfaces.panel(
                        radius: 28,
                        shadowDy: 8,
                        shadowAlpha: 0.2,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 44, 22, 22),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            CozyTitle(
                              copy.title,
                              fontSize: 34,
                              color: titleColor,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              copy.body,
                              textAlign: TextAlign.center,
                              style: GameTypography.secondary,
                            ),
                            const SizedBox(height: 18),
                            // Only offer a revive that can actually rescue this
                            // failure (second-pass audit P1.5).
                            if (canReviveFrom(session.failReason)) ...<Widget>[
                              _WatchRow(
                                label: copy.rescueLabel,
                                onTap: onRevive,
                              ),
                              const SizedBox(height: 14),
                            ],
                            CozyButton(
                              label: 'RETRY',
                              onTap: onRetry,
                              fontSize: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Image.asset(
                    cozyAsset('icon/skull.png'),
                    width: 74,
                    height: 74,
                  ),
                ],
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
        "TIME'S UP!",
        'Freeze time or clear faster before the shelf timer expires.',
        'Add time',
      ),
      LevelFailReason.laneExhausted => const _LossCopy(
        'MISSED!',
        'A required conveyor item left the lane before it was sorted.',
        'Replay lane',
      ),
      LevelFailReason.noUsefulMoves => const _LossCopy(
        'STUCK!',
        'The remaining moves cannot create a clear or rescue path.',
        'Shuffle board',
      ),
      LevelFailReason.moveLimitExceeded => const _LossCopy(
        'OUT OF MOVES',
        'The order needed fewer shelf moves.',
        'Add 5 moves',
      ),
      LevelFailReason.objectiveImpossible => const _LossCopy(
        'ORDER LOST',
        'A required target is no longer available in the board or lanes.',
        'Retry order',
      ),
      LevelFailReason.blockerRemaining => const _LossCopy(
        'BLOCKED!',
        'A blocker is still preventing the final sort.',
        'Use hammer',
      ),
      LevelFailReason.reserveMismanaged ||
      LevelFailReason.boardJammed ||
      LevelFailReason.none => const _LossCopy(
        'SHELF JAMMED',
        'The board has no clean rescue path left.',
        'Shuffle board',
      ),
    };
  }
}

class _WatchRow extends StatelessWidget {
  const _WatchRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: GameSurfaces.panel(
          color: GameColors.sunny,
          radius: 18,
          borderWidth: 3,
          shadowDy: 4,
        ),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: <Widget>[
              Image.asset(
                cozyAsset('reward/claquete.png'),
                width: 42,
                height: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(label, style: GameTypography.compactLabel),
                    Text(
                      'Watch a short video',
                      style: GameTypography.secondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              DecoratedBox(
                decoration: GameSurfaces.button(
                  color: GameColors.leaf,
                  radius: 13,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  child: Text(
                    'WATCH',
                    style: GameTypography.compactLabel.copyWith(
                      color: const Color(0xFFFFFFFF),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _LossCopy {
  const _LossCopy(this.title, this.body, this.rescueLabel);

  final String title;
  final String body;
  final String rescueLabel;
}
