import 'package:flutter/material.dart';

import '../../../application/game_session/game_session_state.dart';
import '../../../application/progression/reward_service.dart';
import '../../../domain/game/star_score.dart';
import '../../design/game_colors.dart';
import '../../design/game_surfaces.dart';
import '../../design/game_typography.dart';
import '../cozy/cozy_widgets.dart';

/// The level-complete overlay. It enters with a scale/fade ceremony and then
/// reveals the earned stars one at a time, from the centre outward (review
/// P1.4 / section 16.2 — the win should feel like a reward moment, not a static
/// panel).
final class WinPanel extends StatefulWidget {
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
  State<WinPanel> createState() => _WinPanelState();
}

class _WinPanelState extends State<WinPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GameSessionState session = widget.session;
    final RewardGrant reward = const RewardService().levelWinReward(
      session.level.levelNumber,
    );
    final bool hardBonus =
        session.level.difficulty == 'hard' ||
        session.level.difficulty == 'superHard';
    final int stars = starsForLevel(
      moveCount: session.moveCount,
      level: session.level,
    );
    return Positioned.fill(
      child: ColoredBox(
        color: GameColors.bezel.withValues(alpha: 0.62),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, Widget? child) {
                  final double t = _controller.value;
                  final double enter = Curves.easeOutBack.transform(
                    (t / 0.45).clamp(0.0, 1.0),
                  );
                  return Opacity(
                    opacity: (t / 0.25).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.85 + 0.15 * enter,
                      child: child,
                    ),
                  );
                },
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
                        _StarRow(stars: stars, animation: _controller),
                        const SizedBox(height: 12),
                        Image.asset(
                          cozyAsset('reward/flower-vase.png'),
                          width: 116,
                          height: 116,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const SizedBox(height: 116),
                        ),
                        const SizedBox(height: 12),
                        DecoratedBox(
                          decoration: GameSurfaces.panel(
                            radius: 20,
                            shadowDy: 4,
                          ),
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
                                      style: GameTypography.compactLabel
                                          .copyWith(
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
                        CozyButton(label: 'NEXT', onTap: widget.onNext),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _SecondaryAction(
                                color: GameColors.sunny,
                                icon: Icons.smart_display_outlined,
                                label: 'Double',
                                onTap: widget.onDoubleReward,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SecondaryAction(
                                color: GameColors.surface,
                                icon: Icons.refresh_rounded,
                                label: 'Replay',
                                onTap: widget.onRetry,
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
      ),
    );
  }
}

/// The three star slots, revealed one at a time from the centre outward as the
/// win animation plays.
class _StarRow extends StatelessWidget {
  const _StarRow({required this.stars, required this.animation});

  final int stars;
  final Animation<double> animation;

  double _reveal(double t, int order) {
    const double start = 0.45;
    const double step = 0.16;
    const double span = 0.24;
    return Curves.easeOutBack.transform(
      ((t - (start + order * step)) / span).clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double t = animation.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            _StarSlot(filled: stars >= 2, size: 50, reveal: _reveal(t, 1)),
            _StarSlot(filled: stars >= 1, size: 66, reveal: _reveal(t, 0)),
            _StarSlot(filled: stars >= 3, size: 50, reveal: _reveal(t, 2)),
          ],
        );
      },
    );
  }
}

class _StarSlot extends StatelessWidget {
  const _StarSlot({required this.filled, required this.size, this.reveal = 1});

  final bool filled;
  final double size;
  final double reveal;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: reveal.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 0.4 + 0.6 * reveal,
        child: Image.asset(
          cozyAsset(filled ? 'icon/star.png' : 'icon/empty-star.png'),
          width: size,
          height: size,
          errorBuilder: (_, _, _) => SizedBox(width: size, height: size),
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
