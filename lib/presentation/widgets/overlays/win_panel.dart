import 'package:flutter/material.dart';

import '../../../application/progression/reward_service.dart';
import '../../../application/game_session/game_session_state.dart';

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
                    Icon(
                      Icons.celebration,
                      size: 44,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Sorted!',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Level ${session.level.levelNumber} | ${session.moveCount} moves | ${session.timer.elapsed.inSeconds}s',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        Chip(
                          avatar: const Icon(Icons.paid, size: 18),
                          label: Text('+${reward.coins}'),
                        ),
                        Chip(
                          avatar: const Icon(
                            Icons.local_fire_department,
                            size: 18,
                          ),
                          label: const Text('Streak +1'),
                        ),
                        if (session.level.difficulty == 'hard')
                          const Chip(
                            avatar: Icon(Icons.workspace_premium, size: 18),
                            label: Text('Hard bonus'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: onNext,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      onPressed: onDoubleReward,
                      icon: const Icon(Icons.smart_display_outlined),
                      label: const Text('Double'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Replay'),
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
