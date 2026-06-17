import 'dart:convert';

import 'package:flutter/services.dart';

import '../../application/content/content_service.dart';
import '../../domain/content/economy_def.dart';
import '../../domain/content/level_def.dart';
import '../../domain/content/product_def.dart';
import '../../domain/content/product_visual_def.dart';
import '../../domain/content/remote_config_def.dart';
import '../../domain/content/theme_def.dart';
import '../../domain/solver/validation_report.dart';
import 'schema_validator.dart';

final class JsonContentLoader {
  JsonContentLoader({
    AssetBundle? bundle,
    SchemaValidator validator = const SchemaValidator(),
  }) : _bundle = bundle ?? rootBundle,
       _validator = validator;

  final AssetBundle _bundle;
  final SchemaValidator _validator;

  Future<ContentService> load() async {
    final productCatalogJson = await _loadJson(
      'assets/data/bundled/product_catalog.json',
    );
    final levelPackJson = await _loadJson(
      'assets/data/bundled/level_pack_000.json',
    );
    final economyJson = await _loadJson(
      'assets/data/bundled/economy_config.json',
    );
    final remoteJson = await _loadJson(
      'assets/data/bundled/remote_defaults.json',
    );
    final themeJson = await _loadJson('assets/data/bundled/theme_catalog.json');
    final eventJson = await _loadJson('assets/data/bundled/event_catalog.json');
    final assetManifestJson = await _loadJson(
      'assets/data/bundled/asset_manifest.json',
    );
    _throwIfInvalid(
      _validator.validateRawContent(
        productCatalogJson: productCatalogJson,
        levelPackJson: levelPackJson,
        economyJson: economyJson,
        remoteConfigJson: remoteJson,
        themeCatalogJson: themeJson,
        eventCatalogJson: eventJson,
        assetManifestJson: assetManifestJson,
      ),
    );
    final ProductCatalog productCatalog = ProductCatalog.fromJson(
      productCatalogJson,
    );
    final LevelPack levelPack = LevelPack.fromJson(levelPackJson);
    final ProductVisualManifest productVisualManifest =
        ProductVisualManifest.fromJson(assetManifestJson);
    _throwIfInvalid(
      _validator.validateParsedContent(
        productCatalog: productCatalog,
        levelPack: levelPack,
        productVisualManifest: productVisualManifest,
      ),
    );
    final List<Object?> themesJson = themeJson['themes']! as List<Object?>;
    return InMemoryContentService(
      GameContent(
        productCatalog: productCatalog,
        levelPack: levelPack,
        economy: EconomyDef.fromJson(economyJson),
        remoteConfig: RemoteConfigDef.fromJson(remoteJson),
        themes: themesJson
            .map((Object? item) {
              return ThemeDef.fromJson(item! as Map<String, Object?>);
            })
            .toList(growable: false),
        eventCatalog: eventJson,
        productVisualManifest: productVisualManifest,
      ),
    );
  }

  Future<Map<String, Object?>> _loadJson(String assetPath) async {
    final String raw = await _bundle.loadString(assetPath);
    return jsonDecode(raw) as Map<String, Object?>;
  }

  void _throwIfInvalid(ValidationReport report) {
    if (report.passed) {
      return;
    }
    final String message = report.issues
        .map((ValidationIssue issue) {
          return '${issue.levelId ?? 'content'} ${issue.code}: ${issue.message}';
        })
        .join('\n');
    throw ContentValidationException(message);
  }
}

final class ContentValidationException implements Exception {
  const ContentValidationException(this.message);

  final String message;

  @override
  String toString() => 'ContentValidationException: $message';
}
