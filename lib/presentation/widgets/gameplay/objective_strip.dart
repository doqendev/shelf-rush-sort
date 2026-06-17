import 'package:flutter/material.dart';

import '../../../application/game_session/game_session_state.dart';
import '../../../domain/game/objective.dart';
import '../../../presentation/design/game_colors.dart';
import '../../../presentation/design/game_surfaces.dart';
import '../../../presentation/design/game_typography.dart';
import '../../../presentation/design/layout_tokens.dart';

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
              decoration: GameSurfaces.panel(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.task_alt_rounded,
                      size: 18,
                      color: GameColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _objectiveText(),
                        style: GameTypography.objective,
                        maxLines: width < 340 ? 2 : 1,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_progressText(), style: GameTypography.secondary),
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

  String _progressText() {
    final ObjectiveState objective = session.objective;
    switch (objective.requirement.type) {
      case ObjectiveType.clearAll:
      case ObjectiveType.timeChallenge:
        return '${session.board.visibleProductCount} left';
      case ObjectiveType.clearSkuTargets:
        final int remaining = objective.remainingTargets.values.fold<int>(
          0,
          (int sum, int count) => sum + count.clamp(0, 999).toInt(),
        );
        return '$remaining left';
      case ObjectiveType.clearCategoryTargets:
        return '${objective.remainingCategoryTargets.length} groups';
      case ObjectiveType.clearSpecialTargets:
        return '${objective.remainingSpecialTargets.length} goals';
      case ObjectiveType.comboTarget:
        return '${objective.maxCombo}/${objective.requirement.comboTarget}';
      case ObjectiveType.laneDeliveryTarget:
        return '${objective.laneDeliveredProducts}/${objective.requirement.laneDeliveryTarget}';
    }
  }
}
