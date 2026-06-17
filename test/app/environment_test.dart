import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/app/environment.dart';

void main() {
  test('parses supported build environments', () {
    expect(AppEnvironment.parse('dev'), AppEnvironment.dev);
    expect(AppEnvironment.parse('QA'), AppEnvironment.qa);
    expect(AppEnvironment.parse('staging'), AppEnvironment.staging);
    expect(AppEnvironment.parse('prod'), AppEnvironment.production);
    expect(AppEnvironment.parse('production'), AppEnvironment.production);
  });

  test('rejects unknown build environments', () {
    expect(() => AppEnvironment.parse('demo'), throwsFormatException);
  });

  test('derives feature switches from environment', () {
    const debugConfig = EnvironmentConfig(environment: AppEnvironment.qa);
    const productionConfig = EnvironmentConfig(
      environment: AppEnvironment.production,
    );

    expect(debugConfig.debugToolsEnabled, isTrue);
    expect(debugConfig.sandboxServicesEnabled, isTrue);
    expect(productionConfig.debugToolsEnabled, isFalse);
    expect(productionConfig.sandboxServicesEnabled, isFalse);
  });

  test('constructs config from dart-define raw value', () {
    final config = EnvironmentConfig.fromDartDefine(rawEnvironment: 'staging');

    expect(config.environment, AppEnvironment.staging);
    expect(config.name, 'staging');
  });
}
