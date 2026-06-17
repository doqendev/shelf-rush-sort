import 'package:go_router/go_router.dart';

import '../presentation/widgets/game_screen.dart';
import '../presentation/widgets/collections/collection_screen.dart';
import '../presentation/widgets/debug/debug_analytics_screen.dart';
import '../presentation/widgets/events/event_screen.dart';
import '../presentation/widgets/map/map_screen.dart';
import '../presentation/widgets/settings/settings_screen.dart';
import '../presentation/widgets/shop/shop_screen.dart';
import 'environment.dart';

GoRouter createRouter({
  required EnvironmentConfig environmentConfig,
  String initialLocation = '/',
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) {
          final int level =
              int.tryParse(state.uri.queryParameters['level'] ?? '') ?? 1;
          return GameScreen(initialLevel: level);
        },
      ),
      GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
      GoRoute(
        path: '/collections',
        builder: (context, state) => const CollectionScreen(),
      ),
      GoRoute(
        path: '/events',
        builder: (context, state) => const EventScreen(),
      ),
      GoRoute(path: '/shop', builder: (context, state) => const ShopScreen()),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      if (environmentConfig.debugToolsEnabled)
        GoRoute(
          path: '/debug/analytics',
          builder: (context, state) => const DebugAnalyticsScreen(),
        ),
    ],
  );
}
