import 'package:flutter/material.dart';

import '../../../domain/content/level_def.dart';
import '../../design/game_colors.dart';
import '../../design/game_surfaces.dart';
import '../../design/game_typography.dart';

/// A short, player-facing lesson shown when a level opens, teaching the one new
/// mental model the level introduces (hands-on v3 P1.2). The game scaffold shows
/// it only until the player makes their first move, so it teaches without
/// covering the board.
final class TeachingBanner extends StatelessWidget {
  const TeachingBanner({super.key, required this.copy});

  final LevelTeachingCopy copy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: DecoratedBox(
        decoration: GameSurfaces.panel(
          color: GameColors.surface,
          radius: 16,
          shadowDy: 4,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: <Widget>[
              Icon(Icons.lightbulb_rounded, size: 22, color: GameColors.sunny),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(copy.headline, style: GameTypography.compactLabel),
                    const SizedBox(height: 2),
                    Text(copy.body, style: GameTypography.secondary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
