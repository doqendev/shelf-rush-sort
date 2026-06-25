import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/boosters/booster_def.dart';
import '../../design/game_colors.dart';
import '../../design/game_surfaces.dart';
import '../../design/game_typography.dart';
import '../cozy/cozy_widgets.dart';

final class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prices = ref
        .watch(contentServiceProvider)
        .content
        .economy
        .boosterPrices;
    final save = ref.watch(playerSaveProvider);

    return Scaffold(
      backgroundColor: GameColors.bgYellow,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Header(coins: save.coins),
              const SizedBox(height: 20),
              Text('BOOSTERS', style: GameTypography.eyebrow),
              const SizedBox(height: 10),
              _BoosterGrid(prices: prices),
              const SizedBox(height: 24),
              Text('COIN PACKS', style: GameTypography.eyebrow),
              const SizedBox(height: 10),
              const _CoinPackRow(
                rewardAsset: 'reward/coin-1.png',
                amount: '100',
                price: r'$0.99',
              ),
              const SizedBox(height: 10),
              const _CoinPackRow(
                rewardAsset: 'reward/coin-3.png',
                amount: '600',
                price: r'$4.99',
              ),
              const SizedBox(height: 10),
              const _CoinPackRow(
                rewardAsset: 'reward/coin-9.png',
                amount: '1500',
                price: r'$9.99',
              ),
              const SizedBox(height: 24),
              Text('MORE', style: GameTypography.eyebrow),
              const SizedBox(height: 10),
              const _RemoveAdsRow(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

final class _Header extends StatelessWidget {
  const _Header({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        CozyTitle('Store', fontSize: 30, color: GameColors.sunny),
        const Spacer(),
        CozyPill(
          color: GameColors.sunny,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Image.asset(
                cozyAsset('icon/coin.png'),
                width: 26,
                height: 26,
                errorBuilder: (BuildContext context, Object error,
                        StackTrace? stack) =>
                    const SizedBox(width: 26, height: 26),
              ),
              const SizedBox(width: 6),
              Text('$coins', style: GameTypography.compactLabel),
            ],
          ),
        ),
        const SizedBox(width: 8),
        CozyIconButton(
          asset: 'btn/clear-x.png',
          size: 40,
          tooltip: 'Close',
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Booster grid
// ---------------------------------------------------------------------------

final class _BoosterGrid extends StatelessWidget {
  const _BoosterGrid({required this.prices});

  final Map<BoosterKind, int> prices;

  static const List<String> _icons = <String>[
    'icon/ray.png',
    'icon/star.png',
    'icon/ray.png',
    'icon/star.png',
  ];

  @override
  Widget build(BuildContext context) {
    final List<BoosterKind> boosters = BoosterKind.values;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        for (int i = 0; i < boosters.length; i++)
          SizedBox(
            width: (MediaQuery.sizeOf(context).width - 44) / 2,
            child: _BoosterCard(
              booster: boosters[i],
              price: prices[boosters[i]] ?? 0,
              iconAsset: _icons[i % _icons.length],
            ),
          ),
      ],
    );
  }
}

final class _BoosterCard extends StatelessWidget {
  const _BoosterCard({
    required this.booster,
    required this.price,
    required this.iconAsset,
  });

  final BoosterKind booster;
  final int price;
  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: GameSurfaces.panel(),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: GameColors.surfaceInset,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: GameColors.ink, width: 3),
                    ),
                    child: SizedBox(
                      width: 58,
                      height: 58,
                      child: Center(
                        child: Image.asset(
                          cozyAsset(iconAsset),
                          width: 36,
                          height: 36,
                          errorBuilder: (BuildContext context, Object error,
                                  StackTrace? stack) =>
                              const SizedBox(width: 36, height: 36),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  booster.name,
                  style: GameTypography.body,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                CozyPill(
                  color: GameColors.sunny,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        cozyAsset('icon/coin.png'),
                        width: 16,
                        height: 16,
                        errorBuilder: (BuildContext context, Object error,
                                StackTrace? stack) =>
                            const SizedBox(width: 16, height: 16),
                      ),
                      const SizedBox(width: 4),
                      Text('$price', style: GameTypography.compactLabel),
                    ],
                  ),
                ),
              ],
            ),
            // Blossom badge (optional static qty indicator)
            Positioned(
              top: -6,
              right: -6,
              child: CozyPill(
                color: GameColors.blossom,
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text('x3', style: GameTypography.compactLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Coin pack row
// ---------------------------------------------------------------------------

final class _CoinPackRow extends StatelessWidget {
  const _CoinPackRow({
    required this.rewardAsset,
    required this.amount,
    required this.price,
  });

  final String rewardAsset;
  final String amount;
  final String price;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: GameSurfaces.panel(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: <Widget>[
            Image.asset(
              cozyAsset(rewardAsset),
              width: 52,
              height: 52,
              errorBuilder: (BuildContext context, Object error,
                      StackTrace? stack) =>
                  const SizedBox(width: 52, height: 52),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('$amount Coins', style: GameTypography.body),
                  Text('One-time purchase', style: GameTypography.secondary),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: null,
              child: DecoratedBox(
                decoration: GameSurfaces.button(color: GameColors.leaf),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Text(
                    price,
                    style: GameTypography.body.copyWith(
                      color: GameColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Remove Ads row
// ---------------------------------------------------------------------------

final class _RemoveAdsRow extends StatelessWidget {
  const _RemoveAdsRow();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: GameSurfaces.panel(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: <Widget>[
            Image.asset(
              cozyAsset('icon/star.png'),
              width: 48,
              height: 48,
              errorBuilder: (BuildContext context, Object error,
                      StackTrace? stack) =>
                  const SizedBox(width: 48, height: 48),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Remove Ads', style: GameTypography.body),
                  Text(
                    'Sandbox purchase adapter wired',
                    style: GameTypography.secondary,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: GameColors.mutedInk),
          ],
        ),
      ),
    );
  }
}
