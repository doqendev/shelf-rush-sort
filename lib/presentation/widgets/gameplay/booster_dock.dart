import 'package:flutter/widgets.dart';

import '../../../application/game_session/game_session_state.dart';

final class BoosterDock extends StatelessWidget {
  const BoosterDock({super.key, required this.session});

  final GameSessionState session;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
