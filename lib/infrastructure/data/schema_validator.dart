import '../../domain/content/level_def.dart';
import '../../domain/content/product_def.dart';
import '../../domain/content/product_visual_def.dart';
import '../../domain/core/value_objects.dart';
import '../../domain/boosters/booster_def.dart';
import '../../domain/solver/solver.dart';
import '../../domain/solver/validation_report.dart';

final class SchemaValidator {
  const SchemaValidator({this.levelValidator = const LevelValidator()});

  final LevelValidator levelValidator;

  ValidationReport validateRawContent({
    required Map<String, Object?> productCatalogJson,
    required Map<String, Object?> levelPackJson,
    required Map<String, Object?> economyJson,
    required Map<String, Object?> remoteConfigJson,
    required Map<String, Object?> themeCatalogJson,
    required Map<String, Object?> eventCatalogJson,
    required Map<String, Object?> assetManifestJson,
  }) {
    final List<ValidationIssue> issues = <ValidationIssue>[
      ..._validateProductCatalogJson(productCatalogJson),
      ..._validateLevelPackJson(levelPackJson),
      ..._validateEconomyJson(economyJson),
      ..._validateRemoteConfigJson(remoteConfigJson),
      ..._validateThemeCatalogJson(themeCatalogJson),
      ..._validateEventCatalogJson(eventCatalogJson),
      ..._validateAssetManifestJson(assetManifestJson),
    ];
    return ValidationReport(issues: issues);
  }

  ValidationReport validateLevelPack(LevelPack pack, ProductCatalog catalog) {
    return levelValidator.validatePack(pack, catalog);
  }

  ValidationReport validateParsedContent({
    required ProductCatalog productCatalog,
    required LevelPack levelPack,
    required ProductVisualManifest productVisualManifest,
  }) {
    final List<ValidationIssue> issues = <ValidationIssue>[];
    final Set<String> seenSkus = <String>{};
    for (final ProductDef product in productCatalog.products) {
      if (!seenSkus.add(product.skuId)) {
        issues.add(
          ValidationIssue(
            code: 'duplicate_sku',
            message: 'SKU ${product.skuId} appears more than once.',
          ),
        );
      }
    }
    if (productCatalog.products.length < 60) {
      issues.add(
        ValidationIssue(
          code: 'insufficient_product_catalog',
          message: 'Expected at least 60 product definitions.',
        ),
      );
    }
    issues.addAll(
      _validateProductVisualCoverage(productCatalog, productVisualManifest),
    );
    issues.addAll(validateLevelPack(levelPack, productCatalog).issues);
    return ValidationReport(issues: issues);
  }

  List<ValidationIssue> _validateProductCatalogJson(Map<String, Object?> json) {
    final List<ValidationIssue> issues = <ValidationIssue>[];
    _requireInt(json, 'schemaVersion', 'product_catalog', issues);
    final Object? products = json['products'];
    if (products is! List<Object?> || products.isEmpty) {
      issues.add(
        const ValidationIssue(
          code: 'product_catalog.products',
          message: 'Product catalog must contain a non-empty products array.',
        ),
      );
      return issues;
    }
    for (final Object? item in products) {
      if (item is! Map<String, Object?>) {
        issues.add(
          const ValidationIssue(
            code: 'product_catalog.product_shape',
            message: 'Every product entry must be an object.',
          ),
        );
        continue;
      }
      _requireString(item, 'skuId', 'product_catalog', issues);
      _requireString(item, 'displayName', 'product_catalog', issues);
      _requireString(item, 'family', 'product_catalog', issues);
      _requireString(item, 'colorHex', 'product_catalog', issues);
      _requireString(item, 'shape', 'product_catalog', issues);
      final Object? tags = item['readabilityTags'];
      if (tags is! List<Object?> || tags.isEmpty) {
        issues.add(
          ValidationIssue(
            code: 'product_catalog.readability_tags',
            message: 'Product ${item['skuId'] ?? '?'} needs readability tags.',
          ),
        );
      }
    }
    return issues;
  }

  List<ValidationIssue> _validateLevelPackJson(Map<String, Object?> json) {
    final List<ValidationIssue> issues = <ValidationIssue>[];
    _requireInt(json, 'schemaVersion', 'level_pack', issues);
    _requireString(json, 'id', 'level_pack', issues);
    _requireInt(json, 'version', 'level_pack', issues);
    final Object? levels = json['levels'];
    if (levels is! List<Object?> || levels.isEmpty) {
      issues.add(
        const ValidationIssue(
          code: 'level_pack.levels',
          message: 'Level pack must contain a non-empty levels array.',
        ),
      );
    }
    return issues;
  }

  List<ValidationIssue> _validateEconomyJson(Map<String, Object?> json) {
    final List<ValidationIssue> issues = <ValidationIssue>[];
    _requireInt(json, 'schemaVersion', 'economy_config', issues);
    _requireInt(json, 'startingCoins', 'economy_config', issues);
    final Object? prices = json['boosterPrices'];
    if (prices is! Map<String, Object?>) {
      issues.add(
        const ValidationIssue(
          code: 'economy_config.booster_prices',
          message: 'Economy config must include boosterPrices.',
        ),
      );
      return issues;
    }
    for (final BoosterKind booster in BoosterKind.values) {
      if (prices[booster.name] is! int) {
        issues.add(
          ValidationIssue(
            code: 'economy_config.missing_booster_price',
            message: 'Missing price for ${booster.name}.',
          ),
        );
      }
    }
    return issues;
  }

  List<ValidationIssue> _validateRemoteConfigJson(Map<String, Object?> json) {
    final List<ValidationIssue> issues = <ValidationIssue>[];
    _requireInt(json, 'schemaVersion', 'remote_defaults', issues);
    _requireInt(json, 'firstInterstitialLevel', 'remote_defaults', issues);
    _requireInt(json, 'adCooldownSeconds', 'remote_defaults', issues);
    final Object? laneMultiplier = json['laneSpeedMultiplier'];
    if (laneMultiplier is! num || laneMultiplier <= 0) {
      issues.add(
        const ValidationIssue(
          code: 'remote_defaults.lane_speed_multiplier',
          message: 'Remote defaults must include a positive lane multiplier.',
        ),
      );
    }
    final Object? flags = json['featureFlags'];
    if (flags is! Map<String, Object?>) {
      issues.add(
        const ValidationIssue(
          code: 'remote_defaults.feature_flags',
          message: 'Remote defaults must include featureFlags.',
        ),
      );
    }
    return issues;
  }

  List<ValidationIssue> _validateThemeCatalogJson(Map<String, Object?> json) {
    final List<ValidationIssue> issues = <ValidationIssue>[];
    _requireInt(json, 'schemaVersion', 'theme_catalog', issues);
    final Object? themes = json['themes'];
    if (themes is! List<Object?> || themes.isEmpty) {
      issues.add(
        const ValidationIssue(
          code: 'theme_catalog.themes',
          message: 'Theme catalog must include at least one theme.',
        ),
      );
    }
    return issues;
  }

  List<ValidationIssue> _validateEventCatalogJson(Map<String, Object?> json) {
    final List<ValidationIssue> issues = <ValidationIssue>[];
    _requireInt(json, 'schemaVersion', 'event_catalog', issues);
    final Object? events = json['events'];
    if (events is! List<Object?> || events.isEmpty) {
      issues.add(
        const ValidationIssue(
          code: 'event_catalog.events',
          message: 'Event catalog must include events.',
        ),
      );
      return issues;
    }
    final Set<String> names = <String>{};
    for (final Object? event in events) {
      if (event is Map<String, Object?> && event['name'] is String) {
        names.add(event['name']! as String);
      }
    }
    for (final String requiredEvent in <String>[
      'level_start',
      'move',
      'invalid_move',
      'triple_clear',
      'level_win',
      'level_fail',
      'level_revive',
      'lane_grab',
      'booster_use',
      'ad_opportunity',
      'ad_impression',
      'ad_reward',
      'economy_transaction',
      'performance_level_load',
      'performance_frame_bucket',
      'memory_warning',
      'asset_load_failure',
    ]) {
      if (!names.contains(requiredEvent)) {
        issues.add(
          ValidationIssue(
            code: 'event_catalog.missing_event',
            message: 'Missing analytics event $requiredEvent.',
          ),
        );
      }
    }
    return issues;
  }

  List<ValidationIssue> _validateAssetManifestJson(Map<String, Object?> json) {
    final List<ValidationIssue> issues = <ValidationIssue>[];
    _requireInt(json, 'schemaVersion', 'asset_manifest', issues);
    final Object? visuals = json['productVisuals'];
    if (visuals is! List<Object?> || visuals.isEmpty) {
      issues.add(
        const ValidationIssue(
          code: 'asset_manifest.product_visuals',
          message: 'Asset manifest must include productVisuals.',
        ),
      );
      return issues;
    }
    for (final Object? item in visuals) {
      if (item is! Map<String, Object?>) {
        issues.add(
          const ValidationIssue(
            code: 'asset_manifest.visual_shape',
            message: 'Every product visual entry must be an object.',
          ),
        );
        continue;
      }
      _requireString(item, 'skuId', 'asset_manifest', issues);
      _requireString(item, 'renderMode', 'asset_manifest', issues);
      _requireString(item, 'shape', 'asset_manifest', issues);
      _requireString(item, 'colorHex', 'asset_manifest', issues);
      final Object? tags = item['silhouetteTags'];
      if (tags is! List<Object?> || tags.isEmpty) {
        issues.add(
          ValidationIssue(
            code: 'asset_manifest.silhouette_tags',
            message: 'Visual ${item['skuId'] ?? '?'} needs silhouette tags.',
          ),
        );
      }
    }
    return issues;
  }

  List<ValidationIssue> _validateProductVisualCoverage(
    ProductCatalog productCatalog,
    ProductVisualManifest manifest,
  ) {
    final List<ValidationIssue> issues = <ValidationIssue>[];
    final Set<SkuId> catalogSkus = <SkuId>{
      for (final ProductDef product in productCatalog.products) product.skuId,
    };
    final Set<SkuId> visualSkus = <SkuId>{};
    for (final ProductVisualDef visual in manifest.productVisuals) {
      if (!visualSkus.add(visual.skuId)) {
        issues.add(
          ValidationIssue(
            code: 'asset_manifest.duplicate_visual',
            message: 'Visual ${visual.skuId} appears more than once.',
          ),
        );
      }
      if (!catalogSkus.contains(visual.skuId)) {
        issues.add(
          ValidationIssue(
            code: 'asset_manifest.unknown_sku',
            message: 'Visual ${visual.skuId} does not exist in catalog.',
          ),
        );
      }
      final ProductDef? product = productCatalog.bySku(visual.skuId);
      if (product != null &&
          (product.shape != visual.shape ||
              product.colorHex.toLowerCase() !=
                  visual.colorHex.toLowerCase())) {
        issues.add(
          ValidationIssue(
            code: 'asset_manifest.visual_mismatch',
            message: 'Visual ${visual.skuId} does not match catalog tokens.',
          ),
        );
      }
    }
    for (final SkuId skuId in catalogSkus) {
      if (!visualSkus.contains(skuId)) {
        issues.add(
          ValidationIssue(
            code: 'asset_manifest.missing_visual',
            message: 'Missing visual manifest entry for $skuId.',
          ),
        );
      }
    }
    return issues;
  }

  void _requireString(
    Map<String, Object?> json,
    String key,
    String scope,
    List<ValidationIssue> issues,
  ) {
    if (json[key] is! String) {
      issues.add(
        ValidationIssue(
          code: '$scope.$key',
          message: '$scope requires string field $key.',
        ),
      );
    }
  }

  void _requireInt(
    Map<String, Object?> json,
    String key,
    String scope,
    List<ValidationIssue> issues,
  ) {
    if (json[key] is! int) {
      issues.add(
        ValidationIssue(
          code: '$scope.$key',
          message: '$scope requires integer field $key.',
        ),
      );
    }
  }
}
