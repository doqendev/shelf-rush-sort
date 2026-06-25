import 'package:flutter/material.dart';

import '../../../application/game_session/game_session_state.dart';
import '../../../domain/game/objective.dart';
import '../../../presentation/design/game_colors.dart';
import '../../../presentation/design/game_surfaces.dart';
import '../../../presentation/design/game_typography.dart';
import '../../../presentation/design/layout_tokens.dart';
import '../cozy/cozy_widgets.dart';

final class ObjectiveStrip extends StatelessWidget {
  const ObjectiveStrip({super.key, required this.session});

  final GameSessionState session;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        return SizedBox(
          height: GameLayoutTokens.objectiveHeightFor(width),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: GameLayoutTokens.horizontalPaddingFor(width),
            ),
            child: DecoratedBox(
              decoration: GameSurfaces.panel(radius: 14, shadowDy: 3),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.task_alt_rounded,
                      size: 18,
                      color: GameColors.leaf,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _objectiveText(),
                        style: GameTypography.objective,
                        maxLines: width < 340 ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ComboPill(combo: session.objective.maxCombo),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _objectiveText() {
    final ObjectiveState objective = session.objective;
    return switch (objective.requirement.type) {
      ObjectiveType.clearAll => 'Clear every product',
      ObjectiveType.clearSkuTargets => 'Fill customer order',
      ObjectiveType.clearCategoryTargets => 'Clear categories',
      ObjectiveType.clearSpecialTargets => 'Clear specials',
      ObjectiveType.comboTarget => 'Build combo chain',
      ObjectiveType.timeChallenge => 'Clear before time runs out',
      ObjectiveType.laneDeliveryTarget => 'Deliver lane products',
    };
  }
}

class _ComboPill extends StatelessWidget {
  const _ComboPill({required this.combo});

  final int combo;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: GameSurfaces.pill(color: GameColors.blossom, shadowDy: 2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.asset(
              cozyAsset('icon/ray.png'),
              width: 15,
              height: 15,
              errorBuilder: (_, _, _) => const SizedBox(width: 15, height: 15),
            ),
            const SizedBox(width: 4),
            Text(
              'x$combo',
              style: GameTypography.compactLabel.copyWith(
                color: const Color(0xFFFFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
