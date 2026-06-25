import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../design/game_colors.dart';
import '../../design/game_surfaces.dart';
import '../../design/game_typography.dart';
import '../cozy/cozy_widgets.dart';

final class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  static const List<String> _sprites = <String>[
    'strawberry',
    'popsicle',
    'banana',
    'honey',
    'smoothie',
    'carrot',
    'lemon-juice',
    'orange-soda',
    'vase',
    'cactus',
    'popsicle-2',
  ];

  String _spriteFor(int index) => _sprites[index % _sprites.length];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentServiceProvider).content;
    final save = ref.watch(playerSaveProvider);
    final products = content.productCatalog.products;
    final int total = products.length;
    final int collected = save.collections.length;

    return Scaffold(
      backgroundColor: GameColors.bgPink,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: <Widget>[
                  CozyIconButton(
                    asset: 'btn/clear-return.png',
                    size: 44,
                    tooltip: 'Back',
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 8),
                  const CozyTitle('Collection', fontSize: 30),
                  const Spacer(),
                  CozyPill(
                    child: Text(
                      '$collected / $total',
                      style: GameTypography.compactLabel,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: total,
                itemBuilder: (BuildContext context, int index) {
                  final product = products[index];
                  final bool discovered = save.collections.containsKey(
                    product.skuId,
                  );
                  return DecoratedBox(
                    decoration: GameSurfaces.panel(radius: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                Opacity(
                                  opacity: discovered ? 1.0 : 0.35,
                                  child: Image.asset(
                                    cozyAsset(
                                      'object-no/${_spriteFor(index)}.png',
                                    ),
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (
                                          BuildContext context,
                                          Object error,
                                          StackTrace? stack,
                                        ) => const SizedBox.shrink(),
                                  ),
                                ),
                                if (!discovered)
                                  const Icon(
                                    Icons.lock_rounded,
                                    color: GameColors.mutedInk,
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.displayName,
                            style: GameTypography.secondary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
