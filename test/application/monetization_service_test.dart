import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/application/monetization/monetization_service.dart';
import 'package:shelf_rush_sort/domain/content/level_def.dart';
import 'package:shelf_rush_sort/domain/game/objective.dart';
import 'package:shelf_rush_sort/infrastructure/ads/ads_service.dart';
import 'package:shelf_rush_sort/infrastructure/analytics/analytics_service.dart';

void main() {
  test(
    'rewarded revive emits ad opportunity, impression, and reward',
    () async {
      final DebugAnalyticsService analytics = DebugAnalyticsService();
      final MonetizationService service = MonetizationService(
        ads: const FakeAdsService(),
        analytics: analytics,
      );

      final result = await service.requestRewardedRevive(_level());

      expect(result.completed, isTrue);
      expect(
        analytics.events.map((event) => event.name),
        containsAll(<String>['ad_opportunity', 'ad_impression', 'ad_reward']),
      );
    },
  );

  test(
    'unavailable ad emits unavailable event and does not complete',
    () async {
      final DebugAnalyticsService analytics = DebugAnalyticsService();
      final MonetizationService service = MonetizationService(
        ads: const _UnavailableAdsService(),
        analytics: analytics,
      );

      final result = await service.requestDoubleReward(_level());

      expect(result.completed, isFalse);
      expect(
        analytics.events.map((event) => event.name),
        contains('ad_unavailable'),
      );
      expect(
        analytics.events.map((event) => event.name),
        isNot(contains('ad_reward')),
      );
    },
  );
}

LevelDef _level() {
  return LevelDef(
    id: 'level_test',
    levelNumber: 1,
    title: 'Test',
    seed: 1,
    objective: ObjectiveRequirement(type: ObjectiveType.clearAll),
    compartments: <CompartmentDef>[
      for (var index = 0; index < 15; index += 1)
        CompartmentDef(index: index, cells: const <String?>[null, null, null]),
    ],
  );
}

final class _UnavailableAdsService implements AdsService {
  const _UnavailableAdsService();

  @override
  Future<bool> isAvailable(AdPlacement placement) async => false;

  @override
  Future<AdResult> show(AdPlacement placement) async {
    return const AdResult(completed: false, errorCode: 'unavailable');
  }
}
