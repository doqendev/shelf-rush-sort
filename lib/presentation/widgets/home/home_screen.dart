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

/// The cozy v2 "Home" hero — title art, a single PLAY-continue button, level
/// progress, and a bottom dock to the rest of the game.
final class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<LevelDef> levels = ref
        .watch(contentServiceProvider)
        .content
        .levelPack
        .levels;
    final PlayerSave save = ref.watch(playerSaveProvider);
    final int maxLevel = levels.isEmpty ? 1 : levels.length;
    final int currentLevel = (save.highestLevelCompleted + 1).clamp(1, maxLevel);
    final double progress = maxLevel == 0
        ? 0
        : (save.highestLevelCompleted / maxLevel).clamp(0, 1).toDouble();

    return Scaffold(
      backgroundColor: GameColors.bgMint,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              cozyAsset('bg/home-hero.png'),
              fit: BoxFit.cover,
              errorBuilder: _blank,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _Counter(asset: 'icon/coin.png', value: '${save.coins}'),
                      const Spacer(),
                      CozyIconButton(
                        asset: 'btn/grass-setting.png',
                        size: 46,
                        tooltip: 'Options',
                        onTap: () => context.push('/settings'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const CozyTitle(
                    'SELF\nRUSH',
                    fontSize: 60,
                    strokeWidth: 6,
                    height: 0.86,
                  ),
                  const SizedBox(height: 14),
                  DecoratedBox(
                    decoration: GameSurfaces.pill(color: GameColors.blossom),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                      child: Text(
                        'SHORT  ·  SHELF SORT',
                        style: TextStyle(
                          fontFamily: GameTypography.fontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 2.5,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                  ),
                  const Expanded(child: _Hero()),
                  Row(
                    children: <Widget>[
                      Text(
                        'LEVEL $currentLevel',
                        style: GameTypography.levelLabel.copyWith(fontSize: 15),
                      ),
                      const Spacer(),
                      Text(
                        '${save.highestLevelCompleted} / $maxLevel',
                        style: GameTypography.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  _ProgressBar(value: progress),
                  const SizedBox(height: 18),
                  CozyButton(
                    label: 'PLAY',
                    height: 72,
                    fontSize: 30,
                    onTap: () => context.go('/?level=$currentLevel'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _DockItem(
                        asset: 'dock/book.png',
                        label: 'Levels',
                        onTap: () => context.push('/map'),
                      ),
                      const SizedBox(width: 14),
                      _DockItem(
                        asset: 'dock/store.png',
                        label: 'Store',
                        onTap: () => context.push('/shop'),
                      ),
                      const SizedBox(width: 14),
                      _DockItem(
                        asset: 'dock/tv.png',
                        label: 'Events',
                        onTap: () => context.push('/events'),
                      ),
                      const SizedBox(width: 14),
                      _DockItem(
                        asset: 'dock/config.png',
                        label: 'Options',
                        onTap: () => context.push('/settings'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _blank(BuildContext context, Object error, StackTrace? stack) =>
    const SizedBox.shrink();

class _Counter extends StatelessWidget {
  const _Counter({required this.asset, required this.value});

  final String asset;
  final String value;

  @override
  Widget build(BuildContext context) {
    return CozyPill(
      padding: const EdgeInsets.fromLTRB(4, 4, 13, 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Image.asset(
            cozyAsset(asset),
            width: 28,
            height: 28,
            errorBuilder: (_, _, _) => const SizedBox(width: 28, height: 28),
          ),
          const SizedBox(width: 6),
          Text(value, style: GameTypography.compactLabel),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              cozyAsset('reward/flower-vase.png'),
              fit: BoxFit.contain,
              errorBuilder: _blank,
            ),
          ),
        ),
        Positioned(
          left: 30,
          top: 14,
          child: Image.asset(
            cozyAsset('deco/butterfly-2.png'),
            width: 40,
            height: 40,
            errorBuilder: (_, _, _) => const SizedBox(width: 40, height: 40),
          ),
        ),
        Positioned(
          right: 34,
          top: 40,
          child: Image.asset(
            cozyAsset('deco/butterfly-7.png'),
            width: 38,
            height: 38,
            errorBuilder: (_, _, _) => const SizedBox(width: 38, height: 38),
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: GameColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GameColors.ink, width: 3),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0, 1).toDouble(),
          child: const DecoratedBox(
            decoration: BoxDecoration(color: GameColors.leaf),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.asset,
    required this.label,
    required this.onTap,
  });

  final String asset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CozyIconButton(asset: asset, size: 54, onTap: onTap),
        const SizedBox(height: 4),
        Text(label, style: GameTypography.compactLabel.copyWith(fontSize: 11)),
      ],
    );
  }
}
