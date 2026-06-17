import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../domain/content/level_def.dart';
import '../../../infrastructure/save/save_repository.dart';

final class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<LevelDef> levels = ref
        .watch(contentServiceProvider)
        .content
        .levelPack
        .levels;
    final PlayerSave save = ref.watch(playerSaveProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Events',
            onPressed: () => context.push('/events'),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            tooltip: 'Collections',
            onPressed: () => context.push('/collections'),
            icon: const Icon(Icons.collections_bookmark_outlined),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.92,
        ),
        itemCount: levels.length,
        itemBuilder: (BuildContext context, int index) {
          final LevelDef level = levels[index];
          final bool unlocked =
              level.levelNumber <= save.highestLevelCompleted + 1;
          return FilledButton.tonalIcon(
            onPressed: unlocked
                ? () => context.go('/?level=${level.levelNumber}')
                : null,
            icon: Icon(unlocked ? Icons.play_arrow : Icons.lock_outline),
            label: Text('${level.levelNumber}'),
          );
        },
      ),
    );
  }
}
