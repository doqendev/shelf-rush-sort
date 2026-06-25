import 'package:flutter/material.dart';

import '../../../application/game_session/game_session_state.dart';
import '../../../domain/boosters/booster_def.dart';
import '../../design/game_surfaces.dart';
import '../cozy/cozy_widgets.dart';

/// The cozy v2 power-up dock — four booster tiles beneath the board, wired to
/// the live session's [useBooster] action.
final class BoosterDock extends StatelessWidget {
  const BoosterDock({super.key, required this.session, this.onUseBooster});

  final GameSessionState session;
  final void Function(BoosterKind booster)? onUseBooster;

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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          for (final _DockBooster booster in _boosters)
            _BoosterTile(
              asset: booster.asset,
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
  const _BoosterTile({required this.asset, this.onTap});

  final String asset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
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
              errorBuilder: (_, _, _) => const SizedBox(width: 34, height: 34),
            ),
          ),
        ),
      ),
    );
  }
}
