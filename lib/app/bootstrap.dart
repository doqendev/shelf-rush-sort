import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import '../infrastructure/ads/ads_service.dart';
import '../infrastructure/ads/mobile_ads_provider.dart';
import '../infrastructure/analytics/analytics_service.dart';
import '../infrastructure/analytics/firebase_analytics_provider.dart';
import '../infrastructure/consent/consent_service.dart';
import '../infrastructure/crash/crash_service.dart';
import '../infrastructure/data/json_content_loader.dart';
import '../infrastructure/iap/purchase_service.dart';
import '../infrastructure/platform/device_info_service.dart';
import '../infrastructure/save/local_save_repository.dart';
import '../infrastructure/save/save_repository.dart';
import '../qa/qa_bridge.dart';
import '../qa/qa_install.dart';
import 'environment.dart';
import 'providers.dart';
import 'shelf_rush_app.dart';

Future<void> bootstrap({EnvironmentConfig? environmentConfig}) async {
  WidgetsFlutterBinding.ensureInitialized();
  setUrlStrategy(const HashUrlStrategy());
  final EnvironmentConfig resolvedEnvironment =
      environmentConfig ?? EnvironmentConfig.fromDartDefine();
  // Expose the QA automation bridge (window.shelfRushQa) in non-production
  // builds only, so reviewers can drive + verify the game headlessly.
  if (resolvedEnvironment.debugToolsEnabled) {
    installQaBridge(QaBridge.instance);
  }
  final contentService = await JsonContentLoader().load();
  final SaveRepository saveRepository = LocalSaveRepository();
  final PlayerSave save =
      await saveRepository.load() ??
      PlayerSave.newPlayer(
        playerId: 'anon_local',
        startingCoins: contentService.content.economy.startingCoins,
      );
  await saveRepository.save(save);
  final ConsentService consentService = ConsentService.fromSave(
    consentState: save.settings.consentState,
    requiresConsentForNonEssentialTracking:
        !resolvedEnvironment.debugToolsEnabled,
  );
  final AnalyticsService baseAnalyticsService =
      resolvedEnvironment.debugToolsEnabled
      ? DebugAnalyticsService()
      : const FirebaseAnalyticsProvider();
  final AnalyticsService analyticsService = ConsentAwareAnalyticsService(
    delegate: baseAnalyticsService,
    consent: consentService,
  );
  final AdsService adsService = resolvedEnvironment.sandboxServicesEnabled
      ? const FakeAdsService()
      : const MobileAdsProvider();
  final PurchaseService purchaseService =
      resolvedEnvironment.sandboxServicesEnabled
      ? const FakePurchaseService()
      : const StorePurchaseService();

  runApp(
    ProviderScope(
      overrides: [
        environmentProvider.overrideWithValue(resolvedEnvironment),
        contentServiceProvider.overrideWithValue(contentService),
        analyticsServiceProvider.overrideWithValue(analyticsService),
        saveRepositoryProvider.overrideWithValue(saveRepository),
        playerSaveProvider.overrideWith((Ref ref) => save),
        adsServiceProvider.overrideWithValue(adsService),
        purchaseServiceProvider.overrideWithValue(purchaseService),
        consentServiceProvider.overrideWithValue(consentService),
        crashServiceProvider.overrideWithValue(const DebugCrashService()),
        deviceInfoServiceProvider.overrideWithValue(const DeviceInfoService()),
      ],
      child: const ShelfRushApp(),
    ),
  );
}
