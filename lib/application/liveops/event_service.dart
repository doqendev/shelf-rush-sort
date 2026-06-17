import '../../domain/content/remote_config_def.dart';

final class LiveEventSummary {
  const LiveEventSummary({
    required this.id,
    required this.title,
    required this.enabled,
  });

  final String id;
  final String title;
  final bool enabled;
}

final class EventService {
  const EventService();

  List<LiveEventSummary> summaries(RemoteConfigDef config) {
    return <LiveEventSummary>[
      LiveEventSummary(
        id: 'daily_reward',
        title: 'Daily Reward',
        enabled: config.featureFlags['dailyReward'] ?? false,
      ),
      LiveEventSummary(
        id: 'collections',
        title: 'Collections',
        enabled: config.featureFlags['collections'] ?? false,
      ),
    ];
  }
}
