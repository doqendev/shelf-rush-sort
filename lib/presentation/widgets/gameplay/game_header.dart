import 'package:flutter/material.dart';

import '../../../application/game_session/game_session_state.dart';
import '../../../presentation/design/game_colors.dart';
import '../../../presentation/design/game_surfaces.dart';
import '../../../presentation/design/game_typography.dart';
import '../../../presentation/design/layout_tokens.dart';

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
                SizedBox.square(
                  dimension: GameLayoutTokens.minHitTarget,
                  child: IconButton(
                    tooltip: 'Pause',
                    onPressed: onPause,
                    icon: const Icon(Icons.pause_rounded),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'Level ${session.level.levelNumber}',
                            style: GameTypography.levelLabel,
                          ),
                          if (session.level.difficulty == 'hard' ||
                              session.level.difficulty == 'superHard') ...[
                            const SizedBox(width: 8),
                            _HeaderBadge(
                              label: session.level.difficulty == 'superHard'
                                  ? 'Super Hard'
                                  : 'Hard',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 96,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _RightStatus(session: session),
                  ),
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
      return _HeaderBadge(
        icon: Icons.timer_outlined,
        label: '${remaining.inSeconds}s',
      );
    }
    if (session.level.moveLimit != null) {
      return _HeaderBadge(
        icon: Icons.swap_horiz,
        label: '${session.moveCount}/${session.level.moveLimit}',
      );
    }
    return const SizedBox(width: GameLayoutTokens.minHitTarget);
  }
}

final class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: GameSurfaces.panel(color: GameColors.surfaceStrong),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 15, color: GameColors.ink),
              const SizedBox(width: 4),
            ],
            Text(label, style: GameTypography.compactLabel),
          ],
        ),
      ),
    );
  }
}
