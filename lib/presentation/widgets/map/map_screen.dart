import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../domain/content/level_def.dart';
import '../../../infrastructure/save/save_repository.dart';
import '../../design/game_colors.dart';
import '../../design/game_surfaces.dart';
import '../../design/game_typography.dart';
import '../cozy/cozy_widgets.dart';

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
      backgroundColor: GameColors.bgBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CozyIconButton(
                    asset: 'btn/clear-return.png',
                    size: 44,
                    tooltip: 'Back',
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/home'),
                  ),
                  const SizedBox(width: 10),
                  const CozyTitle('Levels', fontSize: 30),
                  const Spacer(),
                  CozyIconButton(
                    asset: 'btn/clear-note.png',
                    size: 42,
                    tooltip: 'Events',
                    onTap: () => context.push('/events'),
                  ),
                  const SizedBox(width: 8),
                  CozyIconButton(
                    asset: 'btn/clear-question.png',
                    size: 42,
                    tooltip: 'Collections',
                    onTap: () => context.push('/collections'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: levels.length,
                  itemBuilder: (BuildContext context, int index) {
                    final LevelDef level = levels[index];
                    final bool unlocked =
                        level.levelNumber <= save.highestLevelCompleted + 1;
                    final bool isCurrent =
                        level.levelNumber == save.highestLevelCompleted + 1;
                    return _LevelTile(
                      number: level.levelNumber,
                      unlocked: unlocked,
                      isCurrent: isCurrent,
                      stars: save.progress.levelStars[level.id] ?? 0,
                      onTap: unlocked
                          ? () => context.go('/?level=${level.levelNumber}')
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.number,
    required this.unlocked,
    required this.isCurrent,
    required this.stars,
    this.onTap,
  });

  final int number;
  final bool unlocked;
  final bool isCurrent;
  final int stars;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = !unlocked
        ? GameColors.surfaceInset
        : isCurrent
        ? GameColors.sunny
        : GameColors.surface;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: GameSurfaces.panel(
          color: color,
          radius: 16,
          borderWidth: 3,
          shadowDy: 4,
        ),
        child: Center(
          child: unlocked
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('$number', style: GameTypography.levelLabel),
                    if (stars > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            for (var i = 0; i < 3; i += 1)
                              Icon(
                                i < stars
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 11,
                                color: i < stars
                                    ? GameColors.sunny
                                    : GameColors.mutedInk,
                              ),
                          ],
                        ),
                      ),
                  ],
                )
              : const Icon(
                  Icons.lock_rounded,
                  size: 20,
                  color: GameColors.mutedInk,
                ),
        ),
      ),
    );
  }
}
