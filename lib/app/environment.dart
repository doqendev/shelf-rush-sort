enum AppEnvironment {
  dev,
  qa,
  staging,
  production;

  static AppEnvironment parse(String value) {
    return switch (value.trim().toLowerCase()) {
      'dev' => AppEnvironment.dev,
      'qa' => AppEnvironment.qa,
      'staging' => AppEnvironment.staging,
      'prod' || 'production' => AppEnvironment.production,
      _ => throw FormatException('Unknown SHELF_RUSH_ENV value: $value'),
    };
  }
}

final class EnvironmentConfig {
  const EnvironmentConfig({required this.environment});

  factory EnvironmentConfig.fromDartDefine({
    String rawEnvironment = const String.fromEnvironment(
      'SHELF_RUSH_ENV',
      defaultValue: 'dev',
    ),
  }) {
    return EnvironmentConfig(environment: AppEnvironment.parse(rawEnvironment));
  }

  final AppEnvironment environment;

  String get name => environment.name;

  bool get debugToolsEnabled {
    return environment == AppEnvironment.dev ||
        environment == AppEnvironment.qa;
  }

  bool get sandboxServicesEnabled => debugToolsEnabled;
}
