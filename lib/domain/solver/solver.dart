import '../content/cozy_product_visuals.dart';
import '../content/level_def.dart';
import '../content/product_def.dart';
import '../core/value_objects.dart';
import '../game/board_rules.dart';
import '../game/board_state.dart';
import '../moving_lanes/moving_lane_def.dart';
import 'bot_simulator.dart';
import 'validation_report.dart';

final class LevelValidator {
  const LevelValidator({this.botSimulator = const BotSimulator()});

  final BotSimulator botSimulator;

  ValidationReport validatePack(LevelPack pack, ProductCatalog catalog) {
    final List<ValidationIssue> issues = <ValidationIssue>[];
    final Map<String, LevelValidationMetrics> metrics =
        <String, LevelValidationMetrics>{};
    final Set<String> seenLevelIds = <String>{};
    final bool productionPack = !pack.id.contains('dev_test');
    for (final LevelDef level in pack.levels) {
      if (!seenLevelIds.add(level.id)) {
        issues.add(
          ValidationIssue(
            code: 'duplicate_level_id',
            levelId: level.id,
            message: 'Level id is duplicated.',
          ),
        );
      }
      final ValidationReport levelReport = validateLevel(
        level,
        catalog,
        productionPack: productionPack,
      );
      issues.addAll(levelReport.issues);
      metrics.addAll(levelReport.metricsByLevel);
    }
    return ValidationReport(issues: issues, metricsByLevel: metrics);
  }

  ValidationReport validateLevel(
    LevelDef level,
    ProductCatalog catalog, {
    bool productionPack = false,
  }) {
    final List<ValidationIssue> issues = <ValidationIssue>[];
    final SolverResult solverResult = botSimulator.solve(level);
    final LevelValidationMetrics metrics = _metricsFor(level, solverResult);

    // P0.1 "artwork is the truth": two different match identities must never
    // share a product sprite within a level (second-pass audit M3).
    final Map<String, List<SkuId>> visualCollisions = _visualCollisions(level);
    for (final MapEntry<String, List<SkuId>> entry
        in visualCollisions.entries) {
      final List<SkuId> grouped = entry.value..sort();
      issues.add(
        ValidationIssue(
          code: 'visual_identity_collision',
          levelId: level.id,
          message:
              'SKUs ${grouped.join(', ')} all render as "${entry.key}" — '
              'different match identities must not share artwork.',
        ),
      );
    }

    if (level.compartments.length != compartmentCount) {
      issues.add(
        ValidationIssue(
          code: 'wrong_compartment_count',
          levelId: level.id,
          message: 'Expected $compartmentCount compartments.',
        ),
      );
    }

    final Set<int> seenIndexes = <int>{};
    final Map<SkuId, int> skuCounts = <SkuId, int>{};
    var visibleSlots = 0;
    var lockedCompartments = 0;
    var decorativeCompartments = 0;
    var laneQueueSlots = 0;
    for (final CompartmentDef compartment in level.compartments) {
      if (!seenIndexes.add(compartment.index)) {
        issues.add(
          ValidationIssue(
            code: 'duplicate_compartment_index',
            levelId: level.id,
            message: 'Compartment ${compartment.index} appears twice.',
          ),
        );
      }
      if (compartment.cells.length != cellsPerCompartment) {
        issues.add(
          ValidationIssue(
            code: 'wrong_cell_count',
            levelId: level.id,
            message: 'Compartment ${compartment.index} does not have 3 cells.',
          ),
        );
      }
      if (compartment.locked) {
        lockedCompartments += 1;
      }
      if (compartment.decorative) {
        decorativeCompartments += 1;
      }
      for (final SkuId? skuId in compartment.cells) {
        if (skuId == null) {
          continue;
        }
        visibleSlots += 1;
        _countSku(skuCounts, skuId);
        if (!catalog.containsSku(skuId)) {
          issues.add(
            ValidationIssue(
              code: 'unknown_sku',
              levelId: level.id,
              message: 'Unknown SKU $skuId.',
            ),
          );
        }
      }
      for (final SkuId skuId in compartment.hidden) {
        _countSku(skuCounts, skuId);
        if (!catalog.containsSku(skuId)) {
          issues.add(
            ValidationIssue(
              code: 'unknown_hidden_sku',
              levelId: level.id,
              message: 'Unknown hidden SKU $skuId.',
            ),
          );
        }
      }
    }
    for (final lane in level.movingLanes) {
      laneQueueSlots += lane.queue.length;
      for (final product in lane.queue) {
        _countSku(skuCounts, product.skuId);
        if (!catalog.containsSku(product.skuId)) {
          issues.add(
            ValidationIssue(
              code: 'unknown_lane_sku',
              levelId: level.id,
              message: 'Unknown lane SKU ${product.skuId}.',
            ),
          );
        }
      }
    }

    final int effectiveVisibleSlots =
        visibleSlots + (level.movingLanes.isEmpty ? 0 : laneQueueSlots);
    final int emptyVisibleSlots = frontCellCount - effectiveVisibleSlots;
    // Tutorial levels are intentionally sparse, guided and partly locked down
    // (a gentle first success), so they are exempt from the dense full-rack
    // opening-quality gates. See the studio-quality upgrade plan, sections 14
    // and 22.
    final bool isTutorial = level.difficulty == 'tutorial';
    // Hand-authored levels (the tutorial, or any level carrying human-review
    // intent) are trusted curated content, so they are exempt from the
    // generated-content quality proxies below (full-rack density, lock bans).
    // The hands-on audit told us to stop using "all 15 compartments active" as
    // the quality bar for the authored opening curriculum (Blocker 1 / Sprint
    // B). Broken-content and solvability checks still apply to every level.
    final bool isCurated = isTutorial || level.humanReview != null;
    if (emptyVisibleSlots > 20 && !isCurated) {
      issues.add(
        ValidationIssue(
          code: 'low_visual_density',
          levelId: level.id,
          message: 'Level opens with too many empty visible slots.',
        ),
      );
    }
    final int activeCompartmentCount =
        level.compartments.length - lockedCompartments - decorativeCompartments;
    if (level.levelNumber <= 15 && !isCurated) {
      if (activeCompartmentCount != compartmentCount) {
        issues.add(
          ValidationIssue(
            code: 'opening_levels_require_full_rack',
            levelId: level.id,
            message: 'Opening levels must keep all 15 compartments playable.',
          ),
        );
      }
      if (lockedCompartments != 0) {
        issues.add(
          ValidationIssue(
            code: 'opening_levels_forbid_locks',
            levelId: level.id,
            message: 'Opening levels must not use generic locked shelves.',
          ),
        );
      }
      if (decorativeCompartments != 0) {
        issues.add(
          ValidationIssue(
            code: 'opening_levels_forbid_decorative_slots',
            levelId: level.id,
            message:
                'Opening levels must not replace gameplay shelves with decorative slots.',
          ),
        );
      }
    } else if (productionPack &&
        activeCompartmentCount < compartmentCount &&
        !isCurated) {
      issues.add(
        ValidationIssue(
          code: 'inactive_compartments_require_explicit_mechanic',
          levelId: level.id,
          message:
              'Inactive production compartments require an authored lock mechanic.',
        ),
      );
    }

    if (productionPack && level.humanReview == null) {
      issues.add(
        ValidationIssue(
          code: 'missing_human_review',
          levelId: level.id,
          message: 'Production levels require human review metadata.',
        ),
      );
    }
    if (productionPack && metrics.duplicatePatternRatio > 0.24 && !isCurated) {
      issues.add(
        ValidationIssue(
          code: 'duplicate_shelf_pattern',
          levelId: level.id,
          message: 'Front shelf pattern repetition exceeds production gate.',
        ),
      );
    }
    if (metrics.riskFlags.contains('lane_required_miss_can_fail')) {
      issues.add(
        ValidationIssue(
          code: 'required_lane_miss_failure',
          levelId: level.id,
          message: 'Required finite lane can become impossible after misses.',
        ),
      );
    }

    for (final MapEntry<SkuId, int> entry in skuCounts.entries) {
      if (entry.value % cellsPerCompartment != 0) {
        issues.add(
          ValidationIssue(
            code: 'sku_count_not_multiple_of_three',
            levelId: level.id,
            message: '${entry.key} count is ${entry.value}.',
          ),
        );
      }
    }

    if (issues.isEmpty) {
      if (!solverResult.solved) {
        issues.add(
          ValidationIssue(
            code: 'solver_failed',
            levelId: level.id,
            message: solverResult.reason ?? 'Solver could not finish level.',
          ),
        );
      }
    }

    return ValidationReport(
      issues: issues,
      metricsByLevel: <String, LevelValidationMetrics>{level.id: metrics},
    );
  }

  void _countSku(Map<SkuId, int> counts, SkuId skuId) {
    counts[skuId] = (counts[skuId] ?? 0) + 1;
  }

  /// Groups of active SKUs in [level] that resolve to the SAME product sprite —
  /// a different-SKU/same-visual collision that breaks "artwork is the truth"
  /// (second-pass audit M3 / P0.1). Empty when every active SKU is distinct.
  Map<String, List<SkuId>> _visualCollisions(LevelDef level) {
    final Set<SkuId> skus = <SkuId>{};
    for (final CompartmentDef compartment in level.compartments) {
      for (final SkuId? sku in compartment.cells) {
        if (sku != null) {
          skus.add(sku);
        }
      }
      skus.addAll(compartment.hidden);
    }
    for (final MovingLaneDef lane in level.movingLanes) {
      for (final MovingLaneProductDef product in lane.queue) {
        skus.add(product.skuId);
      }
    }
    skus.addAll(level.objective.targetCounts.keys);
    final Map<String, List<SkuId>> byVisual = <String, List<SkuId>>{};
    for (final SkuId sku in skus) {
      byVisual.putIfAbsent(productVisualForSku(sku), () => <SkuId>[]).add(sku);
    }
    byVisual.removeWhere((_, List<SkuId> grouped) => grouped.length < 2);
    return byVisual;
  }

  LevelValidationMetrics _metricsFor(
    LevelDef level,
    SolverResult solverResult,
  ) {
    final BoardRules boardRules = BoardRules(
      allowSameCompartmentMoves: level.rules.allowSameCompartmentMoves,
    );
    final BoardState board = boardRules
        .resolveBoard(level.createBoardState())
        .state;
    final int activeCompartments = level.compartments.where((
      CompartmentDef compartment,
    ) {
      return !compartment.locked && !compartment.decorative;
    }).length;
    final int occupiedFront = level.compartments.fold<int>(0, (
      int count,
      CompartmentDef compartment,
    ) {
      return count +
          compartment.cells.where((SkuId? skuId) => skuId != null).length;
    });
    final int lockedCompartments = level.compartments
        .where((CompartmentDef compartment) => compartment.locked)
        .length;
    final Set<SkuId> uniqueSkus = <SkuId>{};
    final Map<String, int> patterns = <String, int>{};
    var hiddenProducts = 0;
    for (final CompartmentDef compartment in level.compartments) {
      final String pattern = compartment.cells.join('|');
      patterns[pattern] = (patterns[pattern] ?? 0) + 1;
      for (final SkuId? skuId in compartment.cells) {
        if (skuId != null) {
          uniqueSkus.add(skuId);
        }
      }
      hiddenProducts += compartment.hidden.length;
      uniqueSkus.addAll(compartment.hidden);
    }
    for (final lane in level.movingLanes) {
      for (final product in lane.queue) {
        uniqueSkus.add(product.skuId);
      }
    }
    final int duplicatePatterns = patterns.values
        .where((int count) => count > 1)
        .fold<int>(0, (int sum, int count) => sum + count);
    final int legalMoves = boardRules.generateLegalMoves(board).length;
    final int usefulMoves = boardRules.usefulMoves(board).length;
    final double averageUsefulMoveRatio = legalMoves == 0
        ? 0
        : usefulMoves / legalMoves;
    final double emptyFrontRatio =
        (frontCellCount - occupiedFront) / frontCellCount;
    final double lockedCompartmentRatio = lockedCompartments / compartmentCount;
    final double duplicatePatternRatio = duplicatePatterns / compartmentCount;
    final double laneDependencyRatio = level.movingLanes.isEmpty
        ? 0
        : level.movingLanes.where((lane) => lane.requiredForObjective).length /
              level.movingLanes.length;
    final double laneMissFailureRisk =
        level.movingLanes.any((lane) {
          return lane.requiredForObjective && lane.behavior.name == 'finite';
        })
        ? 1
        : 0;
    final List<String> riskFlags = <String>[
      if (emptyFrontRatio > 0.45 && level.difficulty != 'tutorial')
        'low_density',
      if (duplicatePatternRatio > 0.24) 'duplicate_patterns',
      if (averageUsefulMoveRatio < 0.08 && legalMoves > 0)
        'low_useful_move_ratio',
      if (laneMissFailureRisk > 0) 'lane_required_miss_can_fail',
      if (!solverResult.solved) 'solver_failed',
    ];
    return LevelValidationMetrics(
      solvable: solverResult.solved,
      minSolutionMoves: solverResult.solved ? solverResult.moves : -1,
      botWinRate: solverResult.solved ? 1 : 0,
      deadEndProbability: solverResult.solved ? 0 : 1,
      averageUsefulMoveRatio: averageUsefulMoveRatio,
      activeCompartmentCount: activeCompartments,
      occupiedFrontCellCount: occupiedFront,
      emptyFrontRatio: emptyFrontRatio,
      lockedCompartmentRatio: lockedCompartmentRatio,
      duplicatePatternRatio: duplicatePatternRatio,
      uniqueSkuCount: uniqueSkus.length,
      hiddenProductCount: hiddenProducts,
      hiddenAutoClearRisk: hiddenProducts == 0 ? 0 : 0.15,
      laneCount: level.movingLanes.length,
      laneDependencyRatio: laneDependencyRatio,
      laneMissFailureRisk: laneMissFailureRisk,
      densityGrade: emptyFrontRatio < 0.25
          ? 'A'
          : emptyFrontRatio < 0.38
          ? 'B'
          : emptyFrontRatio < 0.48
          ? 'C'
          : 'D',
      difficultyGrade: level.difficulty,
      riskFlags: riskFlags,
    );
  }
}
