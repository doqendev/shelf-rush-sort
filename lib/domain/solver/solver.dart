import '../content/level_def.dart';
import '../content/product_def.dart';
import '../core/value_objects.dart';
import 'bot_simulator.dart';
import 'validation_report.dart';

final class LevelValidator {
  const LevelValidator({this.botSimulator = const BotSimulator()});

  final BotSimulator botSimulator;

  ValidationReport validatePack(LevelPack pack, ProductCatalog catalog) {
    final List<ValidationIssue> issues = <ValidationIssue>[];
    final Set<String> seenLevelIds = <String>{};
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
      issues.addAll(validateLevel(level, catalog).issues);
    }
    return ValidationReport(issues: issues);
  }

  ValidationReport validateLevel(LevelDef level, ProductCatalog catalog) {
    final List<ValidationIssue> issues = <ValidationIssue>[];
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
      if (compartment.locked || compartment.decorative) {
        lockedCompartments += 1;
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
    if (emptyVisibleSlots > 20 && lockedCompartments < 6) {
      issues.add(
        ValidationIssue(
          code: 'low_visual_density',
          levelId: level.id,
          message: 'Level opens with too many empty visible slots.',
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
      final SolverResult solverResult = botSimulator.solve(level);
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

    return ValidationReport(issues: issues);
  }

  void _countSku(Map<SkuId, int> counts, SkuId skuId) {
    counts[skuId] = (counts[skuId] ?? 0) + 1;
  }
}
