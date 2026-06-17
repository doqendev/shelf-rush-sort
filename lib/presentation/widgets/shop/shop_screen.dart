import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/boosters/booster_def.dart';

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
      appBar: AppBar(
        title: Text('Shop  |  ${save.coins} coins'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          for (final BoosterKind booster in BoosterKind.values)
            Card(
              child: ListTile(
                leading: const Icon(Icons.bolt),
                title: Text(booster.name),
                subtitle: Text('${prices[booster] ?? 0} coins'),
                trailing: FilledButton(
                  onPressed: null,
                  child: const Text('Buy'),
                ),
              ),
            ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.block),
              title: Text('Remove Ads'),
              subtitle: Text('Sandbox purchase adapter wired'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
        ],
      ),
    );
  }
}
