import 'package:flutter/material.dart';

import '../../../application/game_session/game_session_state.dart';
import '../../../application/progression/reward_service.dart';
import '../../design/game_colors.dart';
import '../../design/game_surfaces.dart';
import '../../design/game_typography.dart';
import '../cozy/cozy_widgets.dart';

final class WinPanel extends StatelessWidget {
  const WinPanel({
    super.key,
    required this.session,
    required this.onNext,
    required this.onDoubleReward,
    required this.onRetry,
  });

  final GameSessionState session;
  final VoidCallback onNext;
  final VoidCallback onDoubleReward;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final RewardGrant reward = const RewardService().levelWinReward(
      session.level.levelNumber,
    );
    final bool hardBonus =
        session.level.difficulty == 'hard' ||
        session.level.difficulty == 'superHard';
    return Positioned.fill(
      child: ColoredBox(
        color: GameColors.bezel.withValues(alpha: 0.62),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: DecoratedBox(
                decoration: GameSurfaces.panel(
                  radius: 28,
                  shadowDy: 8,
                  shadowAlpha: 0.2,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const CozyTitle(
                        'LEVEL\nCOMPLETE',
                        fontSize: 38,
                        strokeWidth: 4.5,
                        height: 0.95,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Image.asset(
                            cozyAsset('icon/star.png'),
                            width: 50,
                            height: 50,
                          ),
                          Image.asset(
                            cozyAsset('icon/star.png'),
                            width: 66,
                            height: 66,
                          ),
                          Image.asset(
                            cozyAsset('icon/star.png'),
                            width: 50,
                            height: 50,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Image.asset(
                        cozyAsset('reward/flower-vase.png'),
                        width: 116,
                        height: 116,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox(height: 116),
                      ),
                      const SizedBox(height: 12),
                      DecoratedBox(
                        decoration: GameSurfaces.panel(radius: 20, shadowDy: 4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Image.asset(
                                cozyAsset('icon/coin.png'),
                                width: 38,
                                height: 38,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '+${reward.coins}',
                                style: GameTypography.levelLabel.copyWith(
                                  fontSize: 22,
                                ),
                              ),
                              if (hardBonus) ...<Widget>[
                                const SizedBox(width: 12),
                                CozyPill(
                                  color: GameColors.blossom,
                                  child: Text(
                                    'Hard bonus',
                                    style: GameTypography.compactLabel.copyWith(
                                      color: const Color(0xFFFFFFFF),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      CozyButton(label: 'NEXT', onTap: onNext),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _SecondaryAction(
                              color: GameColors.sunny,
                              icon: Icons.smart_display_outlined,
                              label: 'Double',
                              onTap: onDoubleReward,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SecondaryAction(
                              color: GameColors.surface,
                              icon: Icons.refresh_rounded,
                              label: 'Replay',
                              onTap: onRetry,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: GameSurfaces.button(color: color, radius: 16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 18, color: GameColors.ink),
              const SizedBox(width: 6),
              Text(label, style: GameTypography.compactLabel),
            ],
          ),
        ),
      ),
    );
  }
}
