import 'package:flutter/material.dart';

import '../../../application/game_session/game_session_state.dart';
import '../../../domain/boosters/booster_def.dart';
import '../../design/game_colors.dart';
import '../../design/game_surfaces.dart';
import '../../design/game_typography.dart';
import '../cozy/cozy_widgets.dart';

/// The cozy v2 power-up dock — four booster tiles beneath the board, each
/// showing its owned count and wired to the live session's booster action. An
/// empty booster dims and shows a "+" so it reads as a get-more upsell
/// (second-pass audit M4).
final class BoosterDock extends StatelessWidget {
  const BoosterDock({
    super.key,
    required this.session,
    this.onUseBooster,
    this.counts = const <BoosterKind, int>{},
  });

  final GameSessionState session;
  final void Function(BoosterKind booster)? onUseBooster;
  final Map<BoosterKind, int> counts;

  static const List<_DockBooster> _boosters = <_DockBooster>[
    _DockBooster(BoosterKind.freezeTime, 'icon/ray.png'),
    _DockBooster(BoosterKind.shuffle, 'ui/arrow2.png'),
    _DockBooster(BoosterKind.hint, 'icon/star.png'),
    _DockBooster(BoosterKind.revealHidden, 'ui/question.png'),
  ];

  @override
  Widget build(BuildContext context) {
    final bool enabled = !session.isEnded && onUseBooster != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          for (final _DockBooster booster in _boosters)
            _BoosterTile(
              asset: booster.asset,
              count: counts[booster.kind] ?? 0,
              onTap: enabled ? () => onUseBooster!(booster.kind) : null,
            ),
        ],
      ),
    );
  }
}

class _DockBooster {
  const _DockBooster(this.kind, this.asset);

  final BoosterKind kind;
  final String asset;
}

class _BoosterTile extends StatelessWidget {
  const _BoosterTile({required this.asset, required this.count, this.onTap});

  final String asset;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool available = count > 0;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Opacity(
            opacity: onTap == null
                ? 0.4
                : available
                ? 1
                : 0.55,
            child: DecoratedBox(
              decoration: GameSurfaces.panel(
                radius: 18,
                borderWidth: 3.5,
                shadowDy: 4,
              ),
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Image.asset(
                  cozyAsset(asset),
                  width: 34,
                  height: 34,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const SizedBox(width: 34, height: 34),
                ),
              ),
            ),
          ),
          Positioned(
            right: -5,
            bottom: -5,
            child: _CountBadge(
              label: available ? '$count' : '+',
              color: available ? GameColors.leaf : GameColors.blossom,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GameColors.ink, width: 2.5),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GameTypography.compactLabel.copyWith(
          fontSize: 12,
          color: const Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}
