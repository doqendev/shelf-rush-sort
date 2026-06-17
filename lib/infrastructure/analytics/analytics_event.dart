final class AnalyticsEvent {
  AnalyticsEvent({
    required this.name,
    Map<String, Object?> parameters = const <String, Object?>{},
    this.essential = false,
  }) : parameters = Map<String, Object?>.unmodifiable(parameters);

  final String name;
  final Map<String, Object?> parameters;
  final bool essential;
}
