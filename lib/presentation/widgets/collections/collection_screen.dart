import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

final class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentServiceProvider).content;
    final save = ref.watch(playerSaveProvider);
    final int collected = save.collections.length;
    final int total = content.productCatalog.products.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Collections')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          Card(
            child: ListTile(
              leading: const Icon(Icons.collections_bookmark_outlined),
              title: const Text('Product Album'),
              subtitle: Text('$collected / $total discovered'),
            ),
          ),
          for (final product in content.productCatalog.products.take(12))
            Card(
              child: ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(product.displayName),
                subtitle: Text(product.readabilityTags.join('  |  ')),
              ),
            ),
        ],
      ),
    );
  }
}
