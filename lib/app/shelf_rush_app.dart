import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../qa/qa_bridge.dart';
import 'app_theme.dart';
import 'providers.dart';
import 'routes.dart';

final class ShelfRushApp extends ConsumerWidget {
  const ShelfRushApp({super.key, this.initialLocation = '/home'});

  final String initialLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final environmentConfig = ref.watch(environmentProvider);
    final router = createRouter(
      environmentConfig: environmentConfig,
      initialLocation: initialLocation,
    );
    if (environmentConfig.debugToolsEnabled) {
      // Bind the container at the app root (not only once a level opens) so
      // resetSave()/getState() work before the first goToLevel — fixes the QA
      // bridge startup race (hands-on v3 P1.1).
      QaBridge.instance
        ..router = router
        ..container = ProviderScope.containerOf(context, listen: false);
    }
    return MaterialApp.router(
      title: 'Shelf Rush Sort',
      debugShowCheckedModeBanner: false,
      theme: ShelfRushTheme.build(),
      routerConfig: router,
    );
  }
}
