// GENERATED (do not edit by hand) — stable per-SKU product visual identity.
// Second-pass audit M3 / P0.1: each SKU maps to exactly one cozy product
// sprite, identical in every level and on the collection screen. The mapping
// is a graph-colouring over the level packs' co-occurrence, so no level has
// two active SKUs sharing a sprite (the content validator enforces this).

const List<String> kCozyProducts = <String>[
  'apple',
  'asparagus',
  'avocado',
  'banana',
  'blackberry',
  'blueberries',
  'cherries',
  'chilli-pepper',
  'coconut',
  'cucumber',
  'dragonfruit',
  'garlic',
  'grapefruit',
  'kiwi',
  'lemon',
  'lettuce',
  'lime',
  'mango',
  'mushroom',
  'onion',
  'orange',
  'papaya',
  'passionfruit',
  'peach',
  'pear',
  'peas',
  'pineapple',
  'plum',
  'pomegranate',
  'raspberry',
  'strawberry',
  'watermelon',
];

const Map<String, String> kSkuProductVisual = <String, String>{
  'sku_000': 'apple',
  'sku_001': 'lemon',
  'sku_002': 'coconut',
  'sku_003': 'asparagus',
  'sku_004': 'cucumber',
  'sku_005': 'lime',
  'sku_006': 'avocado',
  'sku_007': 'kiwi',
  'sku_008': 'banana',
  'sku_009': 'dragonfruit',
  'sku_010': 'blackberry',
  'sku_011': 'garlic',
  'sku_012': 'blueberries',
  'sku_013': 'grapefruit',
  'sku_014': 'cherries',
  'sku_015': 'lemon',
  'sku_016': 'chilli-pepper',
  'sku_017': 'lettuce',
  'sku_018': 'coconut',
  'sku_019': 'lime',
  'sku_020': 'cucumber',
  'sku_021': 'kiwi',
  'sku_022': 'avocado',
  'sku_023': 'dragonfruit',
  'sku_024': 'banana',
  'sku_025': 'garlic',
  'sku_026': 'blackberry',
  'sku_027': 'apple',
  'sku_028': 'blueberries',
  'sku_029': 'grapefruit',
  'sku_030': 'cherries',
  'sku_031': 'lemon',
  'sku_032': 'chilli-pepper',
  'sku_033': 'lettuce',
  'sku_034': 'coconut',
  'sku_035': 'kiwi',
  'sku_036': 'cucumber',
  'sku_037': 'mango',
  'sku_038': 'dragonfruit',
  'sku_039': 'asparagus',
  'sku_040': 'garlic',
  'sku_041': 'lime',
  'sku_042': 'avocado',
  'sku_043': 'grapefruit',
  'sku_044': 'banana',
  'sku_045': 'lemon',
  'sku_046': 'blackberry',
  'sku_047': 'lettuce',
  'sku_048': 'blueberries',
  'sku_049': 'kiwi',
  'sku_050': 'cherries',
  'sku_051': 'mango',
  'sku_052': 'chilli-pepper',
  'sku_053': 'mushroom',
  'sku_054': 'dragonfruit',
  'sku_055': 'onion',
  'sku_056': 'garlic',
  'sku_057': 'orange',
  'sku_058': 'grapefruit',
  'sku_059': 'papaya',
};

/// Stable product sprite key for [skuId]; deterministic fallback for unknowns.
String productVisualForSku(String skuId) {
  final String? mapped = kSkuProductVisual[skuId];
  if (mapped != null) {
    return mapped;
  }
  var hash = 0;
  for (final int unit in skuId.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return kCozyProducts[hash % kCozyProducts.length];
}
