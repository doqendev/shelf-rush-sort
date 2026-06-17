import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_rush_sort/app/environment.dart';
import 'package:shelf_rush_sort/app/providers.dart';
import 'package:shelf_rush_sort/app/shelf_rush_app.dart';
import 'package:shelf_rush_sort/infrastructure/analytics/analytics_service.dart';

void main() {
  testWidgets('ShelfRushApp exposes debug analytics in debug environments', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          environmentProvider.overrideWithValue(
            const EnvironmentConfig(environment: AppEnvironment.qa),
          ),
          analyticsServiceProvider.overrideWithValue(DebugAnalyticsService()),
        ],
        child: const ShelfRushApp(initialLocation: '/debug/analytics'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ShelfRushApp), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('No events'), findsOneWidget);
  });
}
