import '../../domain/content/level_def.dart';
import '../../infrastructure/ads/ads_service.dart';
import '../../infrastructure/analytics/analytics_event.dart';
import '../../infrastructure/analytics/analytics_service.dart';

enum RewardedFlowKind { revive, doubleReward, freeBooster }

final class RewardedFlowResult {
  const RewardedFlowResult({
    required this.kind,
    required this.completed,
    this.adResult,
  });

  final RewardedFlowKind kind;
  final bool completed;
  final AdResult? adResult;
}

final class MonetizationService {
  const MonetizationService({required this.ads, required this.analytics});

  final AdsService ads;
  final AnalyticsService analytics;

  Future<RewardedFlowResult> requestRewardedRevive(LevelDef level) {
    return _showRewarded(
      level: level,
      kind: RewardedFlowKind.revive,
      placement: AdPlacement.rewardedRevive,
    );
  }

  Future<RewardedFlowResult> requestDoubleReward(LevelDef level) {
    return _showRewarded(
      level: level,
      kind: RewardedFlowKind.doubleReward,
      placement: AdPlacement.rewardedDoubleReward,
    );
  }

  Future<RewardedFlowResult> _showRewarded({
    required LevelDef level,
    required RewardedFlowKind kind,
    required AdPlacement placement,
  }) async {
    await analytics.track(
      AnalyticsEvent(
        name: 'ad_opportunity',
        parameters: <String, Object?>{
          'level_id': level.id,
          'level_number': level.levelNumber,
          'placement': placement.name,
          'flow': kind.name,
        },
      ),
    );

    final bool available = await ads.isAvailable(placement);
    if (!available) {
      await analytics.track(
        AnalyticsEvent(
          name: 'ad_unavailable',
          parameters: <String, Object?>{
            'level_id': level.id,
            'placement': placement.name,
            'flow': kind.name,
          },
        ),
      );
      return RewardedFlowResult(kind: kind, completed: false);
    }

    final AdResult adResult = await ads.show(placement);
    await analytics.track(
      AnalyticsEvent(
        name: 'ad_impression',
        parameters: <String, Object?>{
          'level_id': level.id,
          'placement': placement.name,
          'flow': kind.name,
          'completed': adResult.completed,
          if (adResult.network != null) 'network': adResult.network,
          if (adResult.errorCode != null) 'error_code': adResult.errorCode,
        },
      ),
    );
    if (adResult.completed) {
      await analytics.track(
        AnalyticsEvent(
          name: 'ad_reward',
          parameters: <String, Object?>{
            'level_id': level.id,
            'placement': placement.name,
            'flow': kind.name,
          },
        ),
      );
    }
    return RewardedFlowResult(
      kind: kind,
      completed: adResult.completed,
      adResult: adResult,
    );
  }
}
