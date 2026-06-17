import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../application/liveops/daily_order_service.dart';
import '../../../application/liveops/event_service.dart';
import '../../../infrastructure/analytics/analytics_event.dart';

final class EventScreen extends ConsumerWidget {
  const EventScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(playerSaveProvider);
    final DailyOrderService dailyService = ref.watch(dailyOrderServiceProvider);
    final DailyRewardState daily = dailyService.evaluate(
      save,
      DateTime.now().toUtc(),
    );
    final List<LiveEventSummary> events = ref
        .watch(eventServiceProvider)
        .summaries(ref.watch(contentServiceProvider).content.remoteConfig);
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          Card(
            child: ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: Text('Daily Reward  |  Day ${daily.streakDay}'),
              subtitle: Text('${daily.rewardCoins} coins'),
              trailing: FilledButton(
                onPressed: daily.canClaim
                    ? () => _claimDailyReward(ref, daily)
                    : null,
                child: Text(daily.canClaim ? 'Claim' : 'Claimed'),
              ),
            ),
          ),
          for (final LiveEventSummary event in events)
            Card(
              child: ListTile(
                leading: Icon(
                  event.enabled
                      ? Icons.event_available
                      : Icons.event_busy_outlined,
                ),
                title: Text(event.title),
                subtitle: Text(event.enabled ? 'Enabled' : 'Disabled'),
              ),
            ),
        ],
      ),
    );
  }

  void _claimDailyReward(WidgetRef ref, DailyRewardState daily) {
    final save = ref.read(playerSaveProvider);
    final updated = ref
        .read(dailyOrderServiceProvider)
        .claim(save, DateTime.now().toUtc());
    if (identical(save, updated)) {
      return;
    }
    ref.read(playerSaveProvider.notifier).state = updated;
    unawaited(ref.read(saveRepositoryProvider).save(updated));
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .track(
            AnalyticsEvent(
              name: 'economy_transaction',
              parameters: <String, Object?>{
                'level_id': 'meta',
                'type': 'grant',
                'currency': 'coins',
                'amount': daily.rewardCoins,
                'reason': 'daily_reward',
                'balance': updated.coins,
              },
            ),
          ),
    );
  }
}
