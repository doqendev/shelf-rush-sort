enum AdPlacement {
  rewardedRevive,
  rewardedDoubleReward,
  freeBooster,
  postLevelInterstitial,
}

final class AdResult {
  const AdResult({required this.completed, this.network, this.errorCode});

  final bool completed;
  final String? network;
  final String? errorCode;
}

abstract interface class AdsService {
  Future<bool> isAvailable(AdPlacement placement);

  Future<AdResult> show(AdPlacement placement);
}

final class FakeAdsService implements AdsService {
  const FakeAdsService();

  @override
  Future<bool> isAvailable(AdPlacement placement) async => true;

  @override
  Future<AdResult> show(AdPlacement placement) async {
    return const AdResult(completed: true, network: 'fake');
  }
}
