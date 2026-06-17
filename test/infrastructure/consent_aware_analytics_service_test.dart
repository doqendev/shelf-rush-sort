import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/infrastructure/analytics/analytics_event.dart';
import 'package:shelf_rush_sort/infrastructure/analytics/analytics_service.dart';
import 'package:shelf_rush_sort/infrastructure/consent/consent_service.dart';

void main() {
  test(
    'drops non-essential events when consent is required and unknown',
    () async {
      final DebugAnalyticsService delegate = DebugAnalyticsService();
      final ConsentAwareAnalyticsService analytics =
          ConsentAwareAnalyticsService(
            delegate: delegate,
            consent: ConsentService(state: ConsentState.unknown),
          );

      await analytics.track(AnalyticsEvent(name: 'level_start'));

      expect(delegate.events, isEmpty);
    },
  );

  test('allows essential events before consent', () async {
    final DebugAnalyticsService delegate = DebugAnalyticsService();
    final ConsentAwareAnalyticsService analytics = ConsentAwareAnalyticsService(
      delegate: delegate,
      consent: ConsentService(state: ConsentState.denied),
    );

    await analytics.track(AnalyticsEvent(name: 'crash', essential: true));

    expect(delegate.events.map((AnalyticsEvent event) => event.name), <String>[
      'crash',
    ]);
  });

  test('allows non-essential events after consent is granted', () async {
    final DebugAnalyticsService delegate = DebugAnalyticsService();
    final ConsentAwareAnalyticsService analytics = ConsentAwareAnalyticsService(
      delegate: delegate,
      consent: ConsentService(state: ConsentState.granted),
    );

    await analytics.track(AnalyticsEvent(name: 'level_start'));

    expect(delegate.events.map((AnalyticsEvent event) => event.name), <String>[
      'level_start',
    ]);
  });

  test('allows non-essential events when consent is not required', () async {
    final DebugAnalyticsService delegate = DebugAnalyticsService();
    final ConsentAwareAnalyticsService analytics = ConsentAwareAnalyticsService(
      delegate: delegate,
      consent: ConsentService(
        state: ConsentState.unknown,
        requiresConsentForNonEssentialTracking: false,
      ),
    );

    await analytics.track(AnalyticsEvent(name: 'debug_event'));

    expect(delegate.events.map((AnalyticsEvent event) => event.name), <String>[
      'debug_event',
    ]);
  });

  test('uses updated consent state for later events', () async {
    final DebugAnalyticsService delegate = DebugAnalyticsService();
    final ConsentService consent = ConsentService(state: ConsentState.unknown);
    final ConsentAwareAnalyticsService analytics = ConsentAwareAnalyticsService(
      delegate: delegate,
      consent: consent,
    );

    await analytics.track(AnalyticsEvent(name: 'before_consent'));
    consent.update(ConsentState.granted);
    await analytics.track(AnalyticsEvent(name: 'after_consent'));

    expect(delegate.events.map((AnalyticsEvent event) => event.name), <String>[
      'after_consent',
    ]);
  });
}
