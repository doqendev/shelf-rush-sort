import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/domain/content/level_def.dart';
import 'package:shelf_rush_sort/domain/content/product_def.dart';
import 'package:shelf_rush_sort/domain/content/product_visual_def.dart';
import 'package:shelf_rush_sort/infrastructure/data/schema_validator.dart';

void main() {
  test('raw bundled content passes schema validation', () async {
    final validator = const SchemaValidator();
    final report = validator.validateRawContent(
      productCatalogJson: await _readJson(
        'assets/data/bundled/product_catalog.json',
      ),
      levelPackJson: await _readJson('assets/data/bundled/level_pack_000.json'),
      economyJson: await _readJson('assets/data/bundled/economy_config.json'),
      remoteConfigJson: await _readJson(
        'assets/data/bundled/remote_defaults.json',
      ),
      themeCatalogJson: await _readJson(
        'assets/data/bundled/theme_catalog.json',
      ),
      eventCatalogJson: await _readJson(
        'assets/data/bundled/event_catalog.json',
      ),
      assetManifestJson: await _readJson(
        'assets/data/bundled/asset_manifest.json',
      ),
    );

    expect(report.issues, isEmpty);
  });

  test('economy schema requires every booster price', () async {
    final Map<String, Object?> economy = await _readJson(
      'assets/data/bundled/economy_config.json',
    );
    final Map<String, Object?> prices = Map<String, Object?>.of(
      economy['boosterPrices']! as Map<String, Object?>,
    )..remove('hint');
    final validator = const SchemaValidator();
    final report = validator.validateRawContent(
      productCatalogJson: await _readJson(
        'assets/data/bundled/product_catalog.json',
      ),
      levelPackJson: await _readJson('assets/data/bundled/level_pack_000.json'),
      economyJson: <String, Object?>{...economy, 'boosterPrices': prices},
      remoteConfigJson: await _readJson(
        'assets/data/bundled/remote_defaults.json',
      ),
      themeCatalogJson: await _readJson(
        'assets/data/bundled/theme_catalog.json',
      ),
      eventCatalogJson: await _readJson(
        'assets/data/bundled/event_catalog.json',
      ),
      assetManifestJson: await _readJson(
        'assets/data/bundled/asset_manifest.json',
      ),
    );

    expect(
      report.issues.map((issue) => issue.code),
      contains('economy_config.missing_booster_price'),
    );
  });

  test('remote defaults require a positive lane speed multiplier', () async {
    final Map<String, Object?> remote = await _readJson(
      'assets/data/bundled/remote_defaults.json',
    );
    final validator = const SchemaValidator();
    final report = validator.validateRawContent(
      productCatalogJson: await _readJson(
        'assets/data/bundled/product_catalog.json',
      ),
      levelPackJson: await _readJson('assets/data/bundled/level_pack_000.json'),
      economyJson: await _readJson('assets/data/bundled/economy_config.json'),
      remoteConfigJson: <String, Object?>{...remote, 'laneSpeedMultiplier': 0},
      themeCatalogJson: await _readJson(
        'assets/data/bundled/theme_catalog.json',
      ),
      eventCatalogJson: await _readJson(
        'assets/data/bundled/event_catalog.json',
      ),
      assetManifestJson: await _readJson(
        'assets/data/bundled/asset_manifest.json',
      ),
    );

    expect(
      report.issues.map((issue) => issue.code),
      contains('remote_defaults.lane_speed_multiplier'),
    );
  });

  test(
    'parsed content requires every product to have a visual manifest',
    () async {
      final Map<String, Object?> productCatalogJson = await _readJson(
        'assets/data/bundled/product_catalog.json',
      );
      final Map<String, Object?> assetManifestJson = await _readJson(
        'assets/data/bundled/asset_manifest.json',
      );
      final List<Object?> visuals = List<Object?>.of(
        assetManifestJson['productVisuals']! as List<Object?>,
      )..removeAt(0);

      final validator = const SchemaValidator();
      final report = validator.validateParsedContent(
        productCatalog: ProductCatalog.fromJson(productCatalogJson),
        levelPack: LevelPack.fromJson(
          await _readJson('assets/data/bundled/level_pack_000.json'),
        ),
        productVisualManifest: ProductVisualManifest.fromJson(<String, Object?>{
          ...assetManifestJson,
          'productVisuals': visuals,
        }),
      );

      expect(
        report.issues.map((issue) => issue.code),
        contains('asset_manifest.missing_visual'),
      );
    },
  );
}

Future<Map<String, Object?>> _readJson(String path) async {
  final String raw = await File(path).readAsString();
  return jsonDecode(raw) as Map<String, Object?>;
}
