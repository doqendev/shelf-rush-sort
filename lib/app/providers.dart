import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../application/content/content_service.dart';
import '../application/liveops/daily_order_service.dart';
import '../application/liveops/event_service.dart';
import '../infrastructure/ads/ads_service.dart';
import '../infrastructure/analytics/analytics_service.dart';
import '../infrastructure/consent/consent_service.dart';
import '../infrastructure/crash/crash_service.dart';
import '../infrastructure/iap/purchase_service.dart';
import '../infrastructure/platform/device_info_service.dart';
import '../infrastructure/remote_config/remote_config_service.dart';
import '../infrastructure/save/save_repository.dart';
import 'environment.dart';

final environmentProvider = Provider<EnvironmentConfig>((Ref ref) {
  throw UnimplementedError('EnvironmentConfig must be provided at bootstrap.');
});

final contentServiceProvider = Provider<ContentService>((Ref ref) {
  throw UnimplementedError('ContentService must be provided at bootstrap.');
});

final analyticsServiceProvider = Provider<AnalyticsService>((Ref ref) {
  throw UnimplementedError('AnalyticsService must be provided at bootstrap.');
});

final saveRepositoryProvider = Provider<SaveRepository>((Ref ref) {
  throw UnimplementedError('SaveRepository must be provided at bootstrap.');
});

final playerSaveProvider = StateProvider<PlayerSave>((Ref ref) {
  throw UnimplementedError('PlayerSave must be provided at bootstrap.');
});

final adsServiceProvider = Provider<AdsService>((Ref ref) {
  throw UnimplementedError('AdsService must be provided at bootstrap.');
});

final purchaseServiceProvider = Provider<PurchaseService>((Ref ref) {
  throw UnimplementedError('PurchaseService must be provided at bootstrap.');
});

final remoteConfigServiceProvider = Provider<RemoteConfigService>((Ref ref) {
  final ContentService content = ref.watch(contentServiceProvider);
  return RemoteConfigService(content.content.remoteConfig);
});

final consentServiceProvider = Provider<ConsentService>((Ref ref) {
  return ConsentService();
});

final crashServiceProvider = Provider<CrashService>((Ref ref) {
  throw UnimplementedError('CrashService must be provided at bootstrap.');
});

final dailyOrderServiceProvider = Provider<DailyOrderService>((Ref ref) {
  return const DailyOrderService();
});

final eventServiceProvider = Provider<EventService>((Ref ref) {
  return const EventService();
});

final deviceInfoServiceProvider = Provider<DeviceInfoService>((Ref ref) {
  return const DeviceInfoService();
});
