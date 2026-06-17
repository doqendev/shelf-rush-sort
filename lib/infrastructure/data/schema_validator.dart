import '../../domain/blockers/blocker_def.dart';
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
      return issues;
    }
    final Set<String> blockersByLevel30 = <String>{};
    final Set<String> hiddenModesByLevel30 = <String>{};
    for (final Object? levelItem in levels) {
      if (levelItem is! Map<String, Object?>) {
        issues.add(
          const ValidationIssue(
            code: 'level_pack.level_shape',
            message: 'Every level entry must be an object.',
          ),
        );
        continue;
      }
      final String? levelId = levelItem['id'] as String?;
      final int? levelNumber = levelItem['levelNumber'] as int?;
      final Object? compartments = levelItem['compartments'];
      if (compartments is! List<Object?> || compartments.isEmpty) {
        issues.add(
          ValidationIssue(
            code: 'level_pack.compartments',
            levelId: levelId,
            message: 'Every level must include compartments.',
          ),
        );
        continue;
      }
      for (final Object? compartmentItem in compartments) {
        if (compartmentItem is! Map<String, Object?>) {
          issues.add(
            ValidationIssue(
              code: 'level_pack.compartment_shape',
              levelId: levelId,
              message: 'Every compartment entry must be an object.',
            ),
          );
          continue;
        }
        _validateBlockerList(
          compartmentItem,
          'cellBlockers',
          levelId,
          issues,
          blockersByLevel30: levelNumber != null && levelNumber <= 30
              ? blockersByLevel30
              : null,
        );
        _validateBlockerList(
          compartmentItem,
          'productBlockers',
          levelId,
          issues,
          blockersByLevel30: levelNumber != null && levelNumber <= 30
              ? blockersByLevel30
              : null,
        );
        _validateHiddenLayers(
          compartmentItem,
          levelId,
          issues,
          hiddenModesByLevel30: levelNumber != null && levelNumber <= 30
              ? hiddenModesByLevel30
              : null,
        );
      }
    }
    if (levels.length >= 30) {
      final Set<String> requiredBlockers = <String>{
        for (final BlockerKind blocker in BlockerKind.values)
          if (blocker != BlockerKind.none) blocker.name,
      };
      final Set<String> missingBlockers = requiredBlockers.difference(
        blockersByLevel30,
      );
      if (missingBlockers.isNotEmpty) {
        issues.add(
          ValidationIssue(
            code: 'level_pack.missing_blocker_showcase',
            message:
                'First 30 levels must showcase blockers: ${missingBlockers.join(', ')}.',
          ),
        );
      }
      final Set<String> requiredHiddenModes = <String>{
        for (final HiddenPreviewMode mode in HiddenPreviewMode.values)
          mode.name,
      };
      final Set<String> missingHiddenModes = requiredHiddenModes.difference(
        hiddenModesByLevel30,
      );
      if (missingHiddenModes.isNotEmpty) {
        issues.add(
          ValidationIssue(
            code: 'level_pack.missing_hidden_preview_showcase',
            message:
                'First 30 levels must showcase hidden preview modes: ${missingHiddenModes.join(', ')}.',
          ),
        );
      }
    }
    return issues;
  }

  void _validateBlockerList(
    Map<String, Object?> json,
    String key,
    String? levelId,
    List<ValidationIssue> issues, {
    Set<String>? blockersByLevel30,
  }) {
    final Object? blockers = json[key];
    if (blockers == null) {
      return;
    }
    if (blockers is! List<Object?> || blockers.length != cellsPerCompartment) {
      issues.add(
        ValidationIssue(
          code: 'level_pack.$key',
          levelId: levelId,
          message: '$key must contain exactly $cellsPerCompartment blockers.',
        ),
      );
      return;
    }
    final Set<String> validNames = <String>{
      for (final BlockerKind blocker in BlockerKind.values) blocker.name,
    };
    for (final Object? blocker in blockers) {
      if (blocker is! String || !validNames.contains(blocker)) {
        issues.add(
          ValidationIssue(
            code: 'level_pack.invalid_blocker',
            levelId: levelId,
            message: '$key contains unknown blocker $blocker.',
          ),
        );
        continue;
      }
      if (blocker != BlockerKind.none.name) {
        blockersByLevel30?.add(blocker);
      }
    }
  }

  void _validateHiddenLayers(
    Map<String, Object?> json,
    String? levelId,
    List<ValidationIssue> issues, {
    Set<String>? hiddenModesByLevel30,
  }) {
    final Object? hiddenLayers = json['hiddenLayers'];
    if (hiddenLayers == null) {
      return;
    }
    if (hiddenLayers is! List<Object?>) {
      issues.add(
        ValidationIssue(
          code: 'level_pack.hidden_layers',
          levelId: levelId,
          message: 'hiddenLayers must be an array.',
        ),
      );
      return;
    }
    final Set<String> validModes = <String>{
      for (final HiddenPreviewMode mode in HiddenPreviewMode.values) mode.name,
    };
    for (final Object? layerItem in hiddenLayers) {
      if (layerItem is! Map<String, Object?>) {
        issues.add(
          ValidationIssue(
            code: 'level_pack.hidden_layer_shape',
            levelId: levelId,
            message: 'Every hidden layer must be an object.',
          ),
        );
        continue;
      }
      final Object? cells = layerItem['cells'];
      if (cells is! List<Object?> || cells.length != cellsPerCompartment) {
        issues.add(
          ValidationIssue(
            code: 'level_pack.hidden_layer_cells',
            levelId: levelId,
            message:
                'Hidden layer cells must contain exactly $cellsPerCompartment entries.',
          ),
        );
      }
      final Object previewMode =
          layerItem['previewMode'] ?? HiddenPreviewMode.exactDim.name;
      if (previewMode is! String || !validModes.contains(previewMode)) {
        issues.add(
          ValidationIssue(
            code: 'level_pack.hidden_preview_mode',
            levelId: levelId,
            message: 'Hidden layer contains unknown preview mode $previewMode.',
          ),
        );
        continue;
      }
      hiddenModesByLevel30?.add(previewMode);
    }
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
    _requireInt(json, 'boosterOfferThreshold', 'remote_defaults', issues);
    _requireInt(json, 'hardLevelFrequency', 'remote_defaults', issues);
    _requireInt(json, 'tutorialAssistanceLevel', 'remote_defaults', issues);
    final Object? laneMultiplier = json['laneSpeedMultiplier'];
    if (laneMultiplier is! num || laneMultiplier <= 0) {
      issues.add(
        const ValidationIssue(
          code: 'remote_defaults.lane_speed_multiplier',
          message: 'Remote defaults must include a positive lane multiplier.',
        ),
      );
    }
    final Object? timerMultiplier = json['timerMultiplier'];
    if (timerMultiplier is! num || timerMultiplier <= 0) {
      issues.add(
        const ValidationIssue(
          code: 'remote_defaults.timer_multiplier',
          message: 'Remote defaults must include a positive timer multiplier.',
        ),
      );
    }
    final Object? rescuePriority = json['failRescuePriority'];
    if (rescuePriority is! List<Object?> || rescuePriority.isEmpty) {
      issues.add(
        const ValidationIssue(
          code: 'remote_defaults.fail_rescue_priority',
          message: 'Remote defaults must include fail rescue priority.',
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
