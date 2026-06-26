import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../application/boosters/booster_inventory_service.dart';
import '../../../domain/boosters/booster_def.dart';
import '../../../infrastructure/save/save_repository.dart';
import '../../design/game_colors.dart';
import '../../design/game_surfaces.dart';
import '../../design/game_typography.dart';
import '../cozy/cozy_widgets.dart';

/// Player-facing booster name/description/icon so the shop never shows raw enum
/// names (second-pass audit P2.1).
class _BoosterPresentation {
  const _BoosterPresentation(this.name, this.description, this.icon);

  final String name;
  final String description;
  final String icon;
}

const Map<BoosterKind, _BoosterPresentation> _boosterPresentation =
    <BoosterKind, _BoosterPresentation>{
      BoosterKind.hint: _BoosterPresentation(
        'Hint',
        'Show a winning move',
        'icon/star.png',
      ),
      BoosterKind.shuffle: _BoosterPresentation(
        'Shuffle',
        'Reshuffle the board',
        'ui/arrow2.png',
      ),
      BoosterKind.hammer: _BoosterPresentation(
        'Hammer',
        'Remove one product',
        'ui/x.png',
      ),
      BoosterKind.freezeTime: _BoosterPresentation(
        'Freeze Time',
        'Stop the timer for 10s',
        'icon/ray.png',
      ),
      BoosterKind.extraShelf: _BoosterPresentation(
        'Extra Shelf',
        'Open a spare shelf',
        'ui/cart.png',
      ),
      BoosterKind.revealHidden: _BoosterPresentation(
        'Reveal',
        'Reveal hidden products',
        'ui/question.png',
      ),
      BoosterKind.slowConveyor: _BoosterPresentation(
        'Slow Lane',
        'Slow the conveyor',
        'ui/arrow.png',
      ),
    };

final class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<BoosterKind, int> prices = ref
        .watch(contentServiceProvider)
        .content
        .economy
        .boosterPrices;
    final PlayerSave save = ref.watch(playerSaveProvider);

    void buy(BoosterKind kind, int price) {
      final PlayerSave current = ref.read(playerSaveProvider);
      if (price <= 0 || current.coins < price) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough coins'),
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }
      final PlayerSave next = const BoosterInventoryService().purchase(
        current,
        kind,
        1,
        price,
      );
      ref.read(playerSaveProvider.notifier).state = next;
      unawaited(ref.read(saveRepositoryProvider).save(next));
    }

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
              _BoosterGrid(prices: prices, owned: save.boosters, onBuy: buy),
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
                errorBuilder: (_, _, _) =>
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
  const _BoosterGrid({
    required this.prices,
    required this.owned,
    required this.onBuy,
  });

  final Map<BoosterKind, int> prices;
  final Map<BoosterKind, int> owned;
  final void Function(BoosterKind kind, int price) onBuy;

  @override
  Widget build(BuildContext context) {
    final List<BoosterKind> boosters = BoosterKind.values;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        for (final BoosterKind kind in boosters)
          SizedBox(
            width: (MediaQuery.sizeOf(context).width - 44) / 2,
            child: _BoosterCard(
              booster: kind,
              price: prices[kind] ?? 0,
              owned: owned[kind] ?? 0,
              onBuy: () => onBuy(kind, prices[kind] ?? 0),
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
    required this.owned,
    required this.onBuy,
  });

  final BoosterKind booster;
  final int price;
  final int owned;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final _BoosterPresentation info =
        _boosterPresentation[booster] ??
        const _BoosterPresentation('Booster', '', 'icon/star.png');
    return DecoratedBox(
      decoration: GameSurfaces.panel(),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Column(
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
                          cozyAsset(info.icon),
                          width: 36,
                          height: 36,
                          errorBuilder: (_, _, _) =>
                              const SizedBox(width: 36, height: 36),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  info.name,
                  style: GameTypography.body,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  info.description,
                  style: GameTypography.secondary,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onBuy,
                  behavior: HitTestBehavior.opaque,
                  child: DecoratedBox(
                    decoration: GameSurfaces.button(
                      color: GameColors.sunny,
                      radius: 13,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Image.asset(
                            cozyAsset('icon/coin.png'),
                            width: 16,
                            height: 16,
                            errorBuilder: (_, _, _) =>
                                const SizedBox(width: 16, height: 16),
                          ),
                          const SizedBox(width: 4),
                          Text('$price', style: GameTypography.compactLabel),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Real owned count (not a fake static badge).
            Positioned(
              top: -6,
              right: -6,
              child: CozyPill(
                color: GameColors.blossom,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text(
                  'x$owned',
                  style: GameTypography.compactLabel.copyWith(
                    color: const Color(0xFFFFFFFF),
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
              errorBuilder: (_, _, _) => const SizedBox(width: 52, height: 52),
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
            // Real IAP is out of scope for this build — show the planned price
            // but mark it as not yet purchasable, so the shop never implies a
            // working purchase (third-pass audit P2.1).
            DecoratedBox(
              decoration: GameSurfaces.panel(color: GameColors.surfaceInset),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text('$price · Soon', style: GameTypography.secondary),
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
              errorBuilder: (_, _, _) => const SizedBox(width: 48, height: 48),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Remove Ads', style: GameTypography.body),
                  Text(
                    'Remove banner & interstitial ads',
                    style: GameTypography.secondary,
                  ),
                ],
              ),
            ),
            // Out of scope for this build — not a working purchase (P2.1).
            DecoratedBox(
              decoration: GameSurfaces.panel(color: GameColors.surfaceInset),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text('Soon', style: GameTypography.secondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
