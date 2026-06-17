import 'ads_service.dart';

final class MobileAdsProvider implements AdsService {
  const MobileAdsProvider();

  @override
  Future<bool> isAvailable(AdPlacement placement) async => false;

  @override
  Future<AdResult> show(AdPlacement placement) async {
    return const AdResult(completed: false, errorCode: 'not_configured');
  }
}
