import 'package:flutter/material.dart';

import '../../../application/game_session/game_session_state.dart';
import '../../../domain/boosters/booster_def.dart';
import '../../../presentation/design/game_colors.dart';
import 'booster_dock.dart';
import 'game_header.dart';
import 'objective_strip.dart';

final class GameScaffold extends StatelessWidget {
  const GameScaffold({
    super.key,
    required this.session,
    required this.viewport,
    required this.onPause,
    this.onUseBooster,
    this.boosterCounts = const <BoosterKind, int>{},
  });

  final GameSessionState session;
  final Widget viewport;
  final VoidCallback onPause;
  final void Function(BoosterKind booster)? onUseBooster;
  final Map<BoosterKind, int> boosterCounts;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: GameColors.bgYellow,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            GameHeader(session: session, onPause: onPause),
            ObjectiveStrip(session: session),
            Expanded(child: viewport),
            BoosterDock(
              session: session,
              onUseBooster: onUseBooster,
              counts: boosterCounts,
            ),
          ],
        ),
      ),
    );
  }
}
