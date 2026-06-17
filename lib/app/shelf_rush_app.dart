import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';
import 'providers.dart';
import 'routes.dart';

final class ShelfRushApp extends ConsumerWidget {
  const ShelfRushApp({super.key, this.initialLocation = '/'});

  final String initialLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final environmentConfig = ref.watch(environmentProvider);
    return MaterialApp.router(
      title: 'Shelf Rush Sort',
      debugShowCheckedModeBanner: false,
      theme: ShelfRushTheme.build(),
      routerConfig: createRouter(
        environmentConfig: environmentConfig,
        initialLocation: initialLocation,
      ),
    );
  }
}
