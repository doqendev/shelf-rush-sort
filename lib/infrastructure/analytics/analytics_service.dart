import 'dart:async';

import '../consent/consent_service.dart';
import 'analytics_event.dart';

abstract interface class AnalyticsService {
  Future<void> track(AnalyticsEvent event);
}

final class ConsentAwareAnalyticsService implements AnalyticsService {
  const ConsentAwareAnalyticsService({
    required this.delegate,
    required this.consent,
  });

  final AnalyticsService delegate;
  final ConsentService consent;

  @override
  Future<void> track(AnalyticsEvent event) async {
    if (event.essential || consent.canTrackNonEssential) {
      await delegate.track(event);
    }
  }
}

final class DebugAnalyticsService implements AnalyticsService {
  DebugAnalyticsService();

  final StreamController<List<AnalyticsEvent>> _eventsController =
      StreamController<List<AnalyticsEvent>>.broadcast(sync: true);
  final List<AnalyticsEvent> events = <AnalyticsEvent>[];

  Stream<List<AnalyticsEvent>> get eventsStream => _eventsController.stream;

  List<AnalyticsEvent> get recentEvents {
    return List<AnalyticsEvent>.unmodifiable(
      events.length <= 80 ? events : events.sublist(events.length - 80),
    );
  }

  @override
  Future<void> track(AnalyticsEvent event) async {
    events.add(event);
    _eventsController.add(recentEvents);
  }

  Future<void> dispose() async {
    await _eventsController.close();
  }
}
