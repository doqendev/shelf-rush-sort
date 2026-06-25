import 'package:flutter/material.dart';

import '../../../application/game_session/game_session_state.dart';
import '../../../presentation/design/game_colors.dart';
import '../../../presentation/design/game_typography.dart';
import '../../../presentation/design/layout_tokens.dart';
import '../cozy/cozy_widgets.dart';

final class GameHeader extends StatelessWidget {
  const GameHeader({super.key, required this.session, required this.onPause});

  final GameSessionState session;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double horizontalPadding = GameLayoutTokens.horizontalPaddingFor(
          width,
        );
        return SizedBox(
          height: GameLayoutTokens.headerHeightFor(width),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              children: <Widget>[
                CozyPill(
                  child: Text(
                    'Level ${session.level.levelNumber}',
                    style: GameTypography.compactLabel,
                  ),
                ),
                if (session.level.difficulty == 'hard' ||
                    session.level.difficulty == 'superHard') ...<Widget>[
                  const SizedBox(width: 8),
                  CozyPill(
                    color: GameColors.blossom,
                    child: Text(
                      session.level.difficulty == 'superHard'
                          ? 'Super Hard'
                          : 'Hard',
                      style: GameTypography.compactLabel.copyWith(
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                _RightStatus(session: session),
                const SizedBox(width: 8),
                CozyIconButton(
                  asset: 'btn/clear-pause.png',
                  onTap: onPause,
                  size: 44,
                  tooltip: 'Pause',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

final class _RightStatus extends StatelessWidget {
  const _RightStatus({required this.session});

  final GameSessionState session;

  @override
  Widget build(BuildContext context) {
    final Duration? remaining = session.timer.remaining;
    if (remaining != null) {
      final int seconds = remaining.inSeconds;
      final String minutes = (seconds ~/ 60).toString().padLeft(2, '0');
      final String secs = (seconds % 60).toString().padLeft(2, '0');
      return CozyPill(
        color: GameColors.sunny,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'TIME',
              style: GameTypography.secondary.copyWith(
                color: GameColors.ink,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 7),
            Text('$minutes:$secs', style: GameTypography.levelLabel),
          ],
        ),
      );
    }
    if (session.level.moveLimit != null) {
      return CozyPill(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.swap_horiz_rounded, size: 16, color: GameColors.ink),
            const SizedBox(width: 4),
            Text(
              '${session.moveCount}/${session.level.moveLimit}',
              style: GameTypography.compactLabel,
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
