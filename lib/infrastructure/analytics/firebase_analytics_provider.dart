import 'analytics_event.dart';
import 'analytics_service.dart';

final class FirebaseAnalyticsProvider implements AnalyticsService {
  const FirebaseAnalyticsProvider();

  @override
  Future<void> track(AnalyticsEvent event) async {
    // Production Firebase SDK integration belongs behind this adapter.
  }
}
