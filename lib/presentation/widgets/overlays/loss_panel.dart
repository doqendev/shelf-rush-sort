import 'package:flutter/material.dart';

import '../../../application/game_session/game_session_state.dart';

final class LossPanel extends StatelessWidget {
  const LossPanel({
    super.key,
    required this.session,
    required this.onRetry,
    required this.onRevive,
  });

  final GameSessionState session;
  final VoidCallback onRetry;
  final VoidCallback onRevive;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0x66000000),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Try Level ${session.level.levelNumber} Again',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(session.failReason.name, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: onRevive,
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Revive'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
