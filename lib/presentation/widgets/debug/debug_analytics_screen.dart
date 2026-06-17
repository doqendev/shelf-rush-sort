import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../infrastructure/analytics/analytics_event.dart';
import '../../../infrastructure/analytics/analytics_service.dart';

final class DebugAnalyticsScreen extends ConsumerWidget {
  const DebugAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AnalyticsService analytics = ref.watch(analyticsServiceProvider);
    final DebugAnalyticsService? debugAnalytics = _debugAnalytics(analytics);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: debugAnalytics == null
          ? const Center(child: Text('Debug analytics unavailable'))
          : StreamBuilder<List<AnalyticsEvent>>(
              initialData: debugAnalytics.recentEvents,
              stream: debugAnalytics.eventsStream,
              builder: (BuildContext context, snapshot) {
                final List<AnalyticsEvent> events =
                    snapshot.data ?? const <AnalyticsEvent>[];
                if (events.isEmpty) {
                  return const Center(child: Text('No events'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: events.length,
                  separatorBuilder: (BuildContext context, int index) {
                    return const SizedBox(height: 8);
                  },
                  itemBuilder: (BuildContext context, int index) {
                    final AnalyticsEvent event =
                        events[events.length - index - 1];
                    return Card(
                      child: ListTile(
                        dense: true,
                        title: Text(event.name),
                        subtitle: Text(event.parameters.toString()),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  DebugAnalyticsService? _debugAnalytics(AnalyticsService analytics) {
    if (analytics is DebugAnalyticsService) {
      return analytics;
    }
    if (analytics is ConsentAwareAnalyticsService &&
        analytics.delegate is DebugAnalyticsService) {
      return analytics.delegate as DebugAnalyticsService;
    }
    return null;
  }
}
