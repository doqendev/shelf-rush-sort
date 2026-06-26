import 'package:flutter/material.dart';

import '../../../application/game_session/game_session_state.dart';
import '../../../domain/game/board_state.dart';
import '../../../domain/game/objective.dart';
import '../../../presentation/design/game_colors.dart';
import '../../../presentation/design/game_surfaces.dart';
import '../../../presentation/design/game_typography.dart';
import '../../../presentation/design/layout_tokens.dart';
import '../cozy/cozy_widgets.dart';

/// The in-game objective strip: a mechanic-specific instruction plus a live
/// progress count ("N left"), per the second-pass audit P1.3. A combo pill is
/// shown only once an actual chain (x2+) happens — never a static `x0`.
final class ObjectiveStrip extends StatelessWidget {
  const ObjectiveStrip({super.key, required this.session});

  final GameSessionState session;

  @override
  Widget build(BuildContext context) {
    final ObjectiveState objective = session.objective;
    final bool showCombo =
        objective.maxCombo >= 2 &&
        objective.requirement.type != ObjectiveType.comboTarget;
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
                      // At very narrow widths (~320px) the full objective copy
                      // used to wrap to two lines inside a one-line-tall strip
                      // and clip (hands-on P1.4). Scale the single line down to
                      // fit instead: it never clips, stays on one line, and
                      // costs no board height on small phones.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _objectiveText(objective.requirement.type),
                          style: GameTypography.objective,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_progressText(), style: GameTypography.compactLabel),
                    if (showCombo) ...<Widget>[
                      const SizedBox(width: 6),
                      _ComboPill(combo: objective.maxCombo),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _objectiveText(ObjectiveType type) {
    return switch (type) {
      ObjectiveType.clearAll => 'Put 3 matching products on one shelf',
      ObjectiveType.clearSkuTargets => 'Fill the customer order',
      ObjectiveType.clearCategoryTargets => 'Clear the categories',
      ObjectiveType.clearSpecialTargets => 'Clear the specials',
      ObjectiveType.comboTarget => 'Build a combo chain',
      ObjectiveType.timeChallenge => 'Clear before time runs out',
      ObjectiveType.laneDeliveryTarget => 'Deliver lane products',
    };
  }

  String _progressText() {
    final ObjectiveState objective = session.objective;
    switch (objective.requirement.type) {
      case ObjectiveType.clearAll:
      case ObjectiveType.timeChallenge:
        return '${_remainingProducts()} left';
      case ObjectiveType.clearSkuTargets:
        return '${_sumRemaining(objective.remainingTargets.values)} left';
      case ObjectiveType.clearCategoryTargets:
        return '${_sumRemaining(objective.remainingCategoryTargets.values)} left';
      case ObjectiveType.clearSpecialTargets:
        return '${_sumRemaining(objective.remainingSpecialTargets.values)} left';
      case ObjectiveType.comboTarget:
        return 'x${objective.maxCombo} / x${objective.requirement.comboTarget}';
      case ObjectiveType.laneDeliveryTarget:
        return '${objective.laneDeliveredProducts} / '
            '${objective.requirement.laneDeliveryTarget}';
    }
  }

  int _remainingProducts() {
    var total = session.board.visibleProductCount;
    for (final CompartmentState compartment in session.board.compartments) {
      total += compartment.hiddenStack.length;
    }
    return total;
  }

  int _sumRemaining(Iterable<int> values) {
    return values.fold(
      0,
      (int sum, int count) => sum + (count > 0 ? count : 0),
    );
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
