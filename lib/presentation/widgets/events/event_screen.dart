import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../application/liveops/daily_order_service.dart';
import '../../../application/liveops/event_service.dart';
import '../../../infrastructure/analytics/analytics_event.dart';
import '../../design/game_colors.dart';
import '../../design/game_surfaces.dart';
import '../../design/game_typography.dart';
import '../cozy/cozy_widgets.dart';

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
      backgroundColor: GameColors.bgBlue,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Cozy header row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Row(
                children: <Widget>[
                  CozyIconButton(
                    asset: 'btn/clear-return.png',
                    size: 44,
                    tooltip: 'Back',
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 8),
                  const CozyTitle('Tasks', fontSize: 30),
                  const Spacer(),
                ],
              ),
            ),
            // Scrollable content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: <Widget>[
                  // Daily reward card
                  _DailyRewardCard(
                    daily: daily,
                    onClaim: daily.canClaim
                        ? () => _claimDailyReward(ref, daily)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  // Live event task cards
                  for (final LiveEventSummary event in events) ...<Widget>[
                    _EventTaskCard(event: event),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        ),
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

class _DailyRewardCard extends StatelessWidget {
  const _DailyRewardCard({required this.daily, required this.onClaim});

  final DailyRewardState daily;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: GameSurfaces.panel(color: GameColors.sunny),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: <Widget>[
            // Coin image
            Image.asset(
              cozyAsset('reward/coin-3.png'),
              width: 50,
              height: 50,
              fit: BoxFit.contain,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stack) =>
                      const SizedBox(width: 50, height: 50),
            ),
            const SizedBox(width: 12),
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Daily Reward · Day ${daily.streakDay}',
                    style: GameTypography.body,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${daily.rewardCoins} coins',
                    style: GameTypography.secondary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Claim button
            GestureDetector(
              onTap: onClaim,
              behavior: HitTestBehavior.opaque,
              child: Opacity(
                opacity: onClaim != null ? 1.0 : 0.5,
                child: DecoratedBox(
                  decoration: GameSurfaces.button(color: GameColors.leaf),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      daily.canClaim ? 'Claim' : 'Claimed',
                      style: GameTypography.body.copyWith(
                        color: GameColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventTaskCard extends StatelessWidget {
  const _EventTaskCard({required this.event});

  final LiveEventSummary event;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: GameSurfaces.panel(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: <Widget>[
            // Rounded inset icon tile with ink border
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: GameColors.surfaceInset,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GameColors.ink, width: 3),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  cozyAsset(event.enabled ? 'icon/star.png' : 'icon/ray.png'),
                  fit: BoxFit.contain,
                  errorBuilder:
                      (BuildContext context, Object error, StackTrace? stack) =>
                          const SizedBox(width: 36, height: 36),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Event title
            Expanded(child: Text(event.title, style: GameTypography.body)),
            const SizedBox(width: 10),
            // Status pill
            CozyPill(
              color: event.enabled ? GameColors.leaf : GameColors.surfaceInset,
              child: Text(
                event.enabled ? 'Enabled' : 'Disabled',
                style: GameTypography.compactLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
