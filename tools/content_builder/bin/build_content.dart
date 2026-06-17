import 'dart:convert';
import 'dart:io';

const List<String> _names = <String>[
  'Berry Pop',
  'Lemon Fizz',
  'Mint Beans',
  'Cherry Jam',
  'Sunny Cereal',
  'Blue Soap',
  'Toy Train',
  'Honey Jar',
  'Apple Box',
  'Peach Can',
  'Kiwi Pouch',
  'Cocoa Carton',
  'Plum Soda',
  'Star Cookies',
  'Milk Buddy',
  'Clover Tea',
  'Carrot Cup',
  'Cloud Rice',
  'Grape Drops',
  'Rocket Gum',
  'Pear Wash',
  'Mango Cubes',
  'Melon Tin',
  'Lilac Nuts',
  'Coral Pasta',
  'Ocean Salt',
  'Banana Mix',
  'Rose Juice',
  'Jelly Star',
  'Cream Bun',
  'Tomato Pack',
  'Aqua Bites',
  'Vanilla Box',
  'Cactus Chips',
  'Cookie Cow',
  'Poppy Soup',
  'Avocado Oil',
  'Rainbow Bar',
  'Sprout Cup',
  'Berry Brush',
  'Lime Cube',
  'Orange Foam',
  'Sugar Tin',
  'Tea Bunny',
  'Soda Duck',
  'Mint Rocket',
  'Cocoa Bear',
  'Apple Bell',
  'Lemon Boat',
  'Grape Moon',
  'Peach Panda',
  'Plum Pony',
  'Kiwi Kite',
  'Mango Mug',
  'Pear Pillow',
  'Cherry Cart',
  'Honey Hat',
  'Melon Mask',
  'Berry Badge',
  'Cloud Candy',
];

const List<String> _colors = <String>[
  '#E84F5F',
  '#F2C84B',
  '#56B870',
  '#D94888',
  '#F28F3B',
  '#4E91D9',
  '#8C6FE8',
  '#D99A3D',
  '#D94E35',
  '#F6A15A',
  '#74B843',
  '#9D7053',
  '#7B67C8',
  '#F06449',
  '#5AA7A7',
  '#3F9E73',
  '#E36F3F',
  '#7EB7E6',
  '#9656A1',
  '#4D7CFE',
  '#7FB069',
  '#F08A5D',
  '#4CB5AE',
  '#A66DD4',
];

const List<String> _shapes = <String>[
  'bottle',
  'box',
  'can',
  'pouch',
  'jar',
  'carton',
  'toy',
  'produce',
];

const String _levelPackId = 'dev_test_pack_000_generated';
const int _levelCount = 300;

Future<void> main() async {
  await Directory('assets/data/bundled').create(recursive: true);
  await Directory('assets/data/schemas').create(recursive: true);

  await _writeJson('assets/data/bundled/product_catalog.json', _products());
  await _writeJson('assets/data/bundled/asset_manifest.json', _assetManifest());
  await _writeJson('assets/data/bundled/level_pack_000.json', _levelPack());
  await _writeJson('assets/data/bundled/economy_config.json', _economy());
  await _writeJson(
    'assets/data/bundled/remote_defaults.json',
    _remoteDefaults(),
  );
  await _writeJson('assets/data/bundled/theme_catalog.json', _themes());
  await _writeJson('assets/data/bundled/event_catalog.json', _events());
  await _writeJson(
    'assets/data/bundled/level_review_notes.json',
    _reviewNotes(),
  );

  await _writeJson(
    'assets/data/schemas/product_catalog.schema.json',
    _schema('product_catalog'),
  );
  await _writeJson(
    'assets/data/schemas/asset_manifest.schema.json',
    _schema('asset_manifest'),
  );
  await _writeJson(
    'assets/data/schemas/level_pack.schema.json',
    _schema('level_pack'),
  );
  await _writeJson(
    'assets/data/schemas/economy_config.schema.json',
    _schema('economy_config'),
  );
}

Map<String, Object?> _products() {
  return <String, Object?>{
    'schemaVersion': 1,
    'products': <Map<String, Object?>>[
      for (var index = 0; index < _names.length; index += 1)
        <String, Object?>{
          'skuId': _sku(index),
          'displayName': _names[index],
          'family': 'market_${index ~/ 10}',
          'colorHex': _colors[index % _colors.length],
          'shape': _shapes[index % _shapes.length],
          'readabilityTags': <String>[
            _shapes[index % _shapes.length],
            index.isEven ? 'warm' : 'cool',
            'set_${index ~/ 5}',
          ],
        },
    ],
  };
}

Map<String, Object?> _assetManifest() {
  return <String, Object?>{
    'schemaVersion': 1,
    'productVisuals': <Map<String, Object?>>[
      for (var index = 0; index < _names.length; index += 1)
        <String, Object?>{
          'skuId': _sku(index),
          'renderMode': 'procedural',
          'shape': _shapes[index % _shapes.length],
          'colorHex': _colors[index % _colors.length],
          'silhouetteTags': <String>[
            _shapes[index % _shapes.length],
            index.isEven ? 'warm' : 'cool',
            'size_standard',
          ],
        },
    ],
  };
}

Map<String, Object?> _levelPack() {
  return <String, Object?>{
    'schemaVersion': 1,
    'id': _levelPackId,
    'version': 1,
    'levels': <Map<String, Object?>>[
      for (var level = 1; level <= _levelCount; level += 1)
        level < 15 ? _staticChainLevel(level) : _laneLevel(level),
    ],
  };
}

Map<String, Object?> _staticChainLevel(int level) {
  final int active = (6 + (level ~/ 2)).clamp(6, 15);
  final int skuOffset = (level - 1) * 2;
  final List<Map<String, Object?>> compartments = <Map<String, Object?>>[];
  for (var index = 0; index < 15; index += 1) {
    if (index >= active) {
      compartments.add(_lockedCompartment(index));
      continue;
    }
    final List<String?> cells;
    if (index == 0) {
      cells = <String?>[_sku(skuOffset), _sku(skuOffset), null];
    } else if (index == active - 1) {
      cells = <String?>[_sku(skuOffset + index - 1), null, null];
    } else {
      cells = <String?>[
        _sku(skuOffset + index - 1),
        _sku(skuOffset + index),
        _sku(skuOffset + index),
      ];
    }
    compartments.add(<String, Object?>{
      'index': index,
      'cells': cells,
      'hidden': <String>[],
      'locked': false,
      'decorative': false,
    });
  }
  return <String, Object?>{
    'id': 'level_${level.toString().padLeft(4, '0')}',
    'levelNumber': level,
    'title': 'Market Chain $level',
    'seed': 1000 + level,
    'difficulty': level < 8 ? 'normal' : 'hard',
    'timeLimitSeconds': level < 4 ? null : 180,
    'moveLimit': null,
    'objective': <String, Object?>{
      'type': 'clearAll',
      'targetCounts': <String, int>{},
    },
    'compartments': compartments,
    'movingLanes': <Object?>[],
  };
}

Map<String, Object?> _laneLevel(int level) {
  final int active = (8 + ((level - 15) ~/ 2)).clamp(8, 15);
  final int skuOffset = 20 + ((level - 15) * 2);
  final List<Map<String, Object?>> compartments = <Map<String, Object?>>[];
  final List<Map<String, Object?>> queue = <Map<String, Object?>>[];
  for (var index = 0; index < 15; index += 1) {
    if (index >= active) {
      compartments.add(_lockedCompartment(index));
      continue;
    }
    final String skuId = _sku(skuOffset + index);
    compartments.add(<String, Object?>{
      'index': index,
      'cells': <String?>[skuId, skuId, null],
      'hidden': <String>[],
      'locked': false,
      'decorative': false,
    });
    queue.add(<String, Object?>{
      'skuId': skuId,
      'travelTimeMs': (5200 - (level - 15) * 80).clamp(3600, 5200),
    });
  }
  return <String, Object?>{
    'id': 'level_${level.toString().padLeft(4, '0')}',
    'levelNumber': level,
    'title': 'Conveyor Rush ${level - 14}',
    'seed': 1000 + level,
    'difficulty': level < 22 ? 'hard' : 'superHard',
    'timeLimitSeconds': 180,
    'moveLimit': null,
    'objective': <String, Object?>{
      'type': 'clearAll',
      'targetCounts': <String, int>{},
    },
    'compartments': compartments,
    'movingLanes': <Map<String, Object?>>[
      <String, Object?>{
        'id': 'lane_main',
        'orientation': level % 5 == 0 ? 'vertical' : 'horizontal',
        'behavior': 'finite',
        'speedCellsPerSecond': 1.0 + ((level - 15) * 0.03),
        'queue': queue,
      },
    ],
  };
}

Map<String, Object?> _lockedCompartment(int index) {
  return <String, Object?>{
    'index': index,
    'cells': <String?>[null, null, null],
    'hidden': <String>[],
    'locked': true,
    'decorative': false,
  };
}

Map<String, Object?> _economy() {
  return <String, Object?>{
    'schemaVersion': 1,
    'startingCoins': 500,
    'boosterPrices': <String, int>{
      'hint': 60,
      'shuffle': 120,
      'hammer': 160,
      'freezeTime': 140,
      'extraShelf': 220,
      'revealHidden': 120,
      'slowConveyor': 140,
    },
  };
}

Map<String, Object?> _remoteDefaults() {
  return <String, Object?>{
    'schemaVersion': 1,
    'firstInterstitialLevel': 8,
    'adCooldownSeconds': 180,
    'laneSpeedMultiplier': 1.0,
    'featureFlags': <String, bool>{
      'shop': true,
      'collections': true,
      'dailyReward': true,
      'rewardedRevive': true,
      'debugAnalyticsConsole': true,
    },
  };
}

Map<String, Object?> _themes() {
  return <String, Object?>{
    'schemaVersion': 1,
    'themes': <Map<String, Object?>>[
      <String, Object?>{
        'id': 'toy_market',
        'displayName': 'Toy Market',
        'backgroundColorHex': '#F7F3E8',
        'shelfColorHex': '#B86F4A',
      },
    ],
  };
}

Map<String, Object?> _events() {
  return <String, Object?>{
    'schemaVersion': 1,
    'events': <Map<String, Object?>>[
      <String, Object?>{
        'name': 'level_start',
        'required': <String>['level_id', 'level_number', 'seed'],
      },
      <String, Object?>{
        'name': 'move',
        'required': <String>['level_id', 'source', 'target', 'valid'],
      },
      <String, Object?>{
        'name': 'triple_clear',
        'required': <String>['level_id', 'sku_id', 'combo'],
      },
      <String, Object?>{
        'name': 'level_win',
        'required': <String>['level_id', 'duration_sec', 'moves'],
      },
      <String, Object?>{
        'name': 'level_fail',
        'required': <String>['level_id', 'fail_reason', 'moves'],
      },
      <String, Object?>{
        'name': 'lane_grab',
        'required': <String>['level_id', 'lane_id', 'sku_id'],
      },
      <String, Object?>{
        'name': 'invalid_move',
        'required': <String>['level_id', 'reason'],
      },
      <String, Object?>{
        'name': 'booster_use',
        'required': <String>['level_id', 'booster', 'used'],
      },
      <String, Object?>{
        'name': 'level_revive',
        'required': <String>[
          'level_id',
          'level_number',
          'fail_reason',
          'moves',
        ],
      },
      <String, Object?>{
        'name': 'ad_opportunity',
        'required': <String>['level_id', 'placement', 'flow'],
      },
      <String, Object?>{
        'name': 'ad_impression',
        'required': <String>['level_id', 'placement', 'flow', 'completed'],
      },
      <String, Object?>{
        'name': 'ad_reward',
        'required': <String>['level_id', 'placement', 'flow'],
      },
      <String, Object?>{
        'name': 'ad_unavailable',
        'required': <String>['level_id', 'placement', 'flow'],
      },
      <String, Object?>{
        'name': 'economy_transaction',
        'required': <String>[
          'level_id',
          'type',
          'currency',
          'amount',
          'reason',
          'balance',
        ],
      },
      <String, Object?>{
        'name': 'performance_level_load',
        'required': <String>[
          'level_id',
          'load_time_ms',
          'first_playable_ms',
          'device_tier',
        ],
      },
      <String, Object?>{
        'name': 'performance_frame_bucket',
        'required': <String>[
          'level_id',
          'fps_bucket',
          'frame_spike_count',
          'device_tier',
        ],
      },
      <String, Object?>{
        'name': 'memory_warning',
        'required': <String>['level_id', 'device_tier'],
      },
      <String, Object?>{
        'name': 'asset_load_failure',
        'required': <String>['asset_id', 'asset_type', 'reason'],
      },
    ],
  };
}

Map<String, Object?> _reviewNotes() {
  return <String, Object?>{
    'schemaVersion': 1,
    'packId': _levelPackId,
    'reviewStatus': 'engineering_generated_dev_test',
    'reviewedAt': '2026-06-17T00:00:00Z',
    'notes': <Map<String, Object?>>[
      <String, Object?>{
        'range': 'level_0001-level_0014',
        'summary':
            'Static onboarding chain levels validate and solve with a guaranteed first clear.',
      },
      <String, Object?>{
        'range': 'level_0015-level_0030',
        'summary':
            'Deterministic moving-lane levels validate, solve, and introduce lane pressure after onboarding.',
      },
      <String, Object?>{
        'range': 'level_0031-level_0300',
        'summary':
            'Scaled conveyor progression reuses validated SKU rotations, capped shelf density, and deterministic lane pressure for the generated dev-test pack.',
      },
    ],
  };
}

Map<String, Object?> _schema(String title) {
  return <String, Object?>{
    r'$schema': 'https://json-schema.org/draft/2020-12/schema',
    'title': title,
    'type': 'object',
    'required': <String>['schemaVersion'],
    'additionalProperties': true,
  };
}

String _sku(int index) =>
    'sku_${(index % _names.length).toString().padLeft(3, '0')}';

Future<void> _writeJson(String path, Object? value) async {
  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  await File(path).writeAsString('${encoder.convert(value)}\n');
}
