import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/domain/blockers/blocker_def.dart';
import 'package:shelf_rush_sort/domain/content/cozy_product_visuals.dart';
import 'package:shelf_rush_sort/domain/content/level_def.dart';
import 'package:shelf_rush_sort/domain/content/product_def.dart';
import 'package:shelf_rush_sort/domain/core/value_objects.dart';
import 'package:shelf_rush_sort/domain/game/board_rules.dart';
import 'package:shelf_rush_sort/domain/game/move.dart';
import 'package:shelf_rush_sort/domain/solver/solver.dart';
import 'package:shelf_rush_sort/domain/solver/validation_report.dart';

/// Levels 2..[curatedThrough] are the hand-authored Sprint B curriculum; the
/// rest of the opening pack still uses the full rack until curated too.
const int curatedThrough = 10;

void main() {
  test('level 1 is a gentle, collision-free teaching board', () async {
    final LevelPack pack = await _verticalSlicePack();
    final LevelDef level = pack.levelByNumber(1);

    // The board shape is intact, but the opening level is now a small guided
    // teaching board (studio-quality upgrade plan, sections 14 and 22): few
    // products, unique-visual SKUs within the 11-sprite budget (so it is
    // collision-free), inactive shelves dimmed via locks, and no time pressure,
    // hidden layers, lanes or blockers.
    expect(level.difficulty, 'tutorial');
    expect(level.compartments, hasLength(compartmentCount));
    expect(_visibleProductCount(level), lessThanOrEqualTo(12));
    expect(_skuCounts(level), hasLength(lessThanOrEqualTo(11)));
    expect(
      level.compartments.where((compartment) => compartment.locked),
      isNotEmpty,
    );
    expect(level.timeLimitSeconds, isNull);
    expect(level.moveLimit, isNull);
    expect(level.movingLanes, isEmpty);
    expect(
      level.compartments.expand((compartment) => compartment.hiddenLayers),
      isEmpty,
    );
    expect(
      level.compartments.expand((compartment) => compartment.cellBlockers),
      everyElement(BlockerKind.none),
    );
  });

  test('level 1 guided hint move completes a triple', () async {
    final LevelDef level = (await _verticalSlicePack()).levelByNumber(1);
    const BoardRules rules = BoardRules();
    // The TutorialController's level-1 hint (compartment 1 cell 0 -> the empty
    // slot of compartment 0) must actually complete a triple on the curated
    // board — fixes the review's "incorrect hard-coded hint" finding (P0.5).
    final result = rules.applyMove(
      level.createBoardState(),
      MoveAction(
        source: CellAddress.fromCompartmentIndex(1, 0),
        target: CellAddress.fromCompartmentIndex(0, 2),
      ),
    );

    expect(result.isValid, isTrue);
    expect(result.clearedTriples, hasLength(1));
    expect(result.clearedTriples.single.skuId, 'sku_000');
  });

  test('curriculum levels 2..N are gentle, solvable and collision-free', () async {
    final LevelPack pack = await _verticalSlicePack();
    final ProductCatalog catalog = await _productCatalog();
    const LevelValidator validator = LevelValidator();
    // The opening curriculum (Blocker 1 / Sprint B): each early level is a
    // gentle, hand-authored teaching board — partly locked, few SKUs — and must
    // be finishable by a cold player. The "all 15 compartments active" rule is a
    // quality proxy the hands-on audit told us to drop here.
    for (var levelNumber = 2; levelNumber <= curatedThrough; levelNumber += 1) {
      final LevelDef level = pack.levelByNumber(levelNumber);
      final ValidationReport report = validator.validateLevel(level, catalog);
      final LevelValidationMetrics metrics = report.metricsByLevel[level.id]!;
      expect(
        metrics.solvable,
        isTrue,
        reason: 'level $levelNumber must be solvable by a cold player',
      );
      expect(
        report.issues.where(
          (ValidationIssue issue) =>
              issue.code == 'visual_identity_collision' ||
              issue.code.startsWith('unknown'),
        ),
        isEmpty,
        reason:
            'level $levelNumber has broken content: '
            '${report.issues.map((ValidationIssue i) => i.code).toList()}',
      );
      expect(
        metrics.uniqueSkuCount,
        lessThanOrEqualTo(6),
        reason: 'level $levelNumber should keep a small, readable SKU set',
      );
      expect(
        metrics.activeCompartmentCount,
        lessThan(compartmentCount),
        reason: 'level $levelNumber should not dump the full rack',
      );
    }
  });

  test(
    'levels (N+1)-15 keep every rack compartment playable until curated',
    () async {
      final LevelPack pack = await _verticalSlicePack();
      for (
        var levelNumber = curatedThrough + 1;
        levelNumber <= 15;
        levelNumber += 1
      ) {
        final LevelDef level = pack.levelByNumber(levelNumber);
        expect(
          level.compartments.where((compartment) {
            return !compartment.locked && !compartment.decorative;
          }),
          hasLength(compartmentCount),
          reason: 'level $levelNumber must use all compartments',
        );
      }
    },
  );

  test('every level renders different SKUs with different sprites (M3)', () async {
    // P0.1 "artwork is the truth": the stable per-SKU manifest must give every
    // active SKU in a level a distinct product sprite — no two match identities
    // share artwork. (CI's validate_levels enforces the same on level_pack_000.)
    final LevelPack pack = await _verticalSlicePack();
    for (final LevelDef level in pack.levels) {
      final Map<String, List<String>> byVisual = <String, List<String>>{};
      for (final String sku in _activeSkus(level)) {
        byVisual
            .putIfAbsent(productVisualForSku(sku), () => <String>[])
            .add(sku);
      }
      byVisual.removeWhere((_, List<String> skus) => skus.length < 2);
      expect(
        byVisual,
        isEmpty,
        reason:
            'level ${level.levelNumber} has different SKUs sharing one sprite: '
            '$byVisual',
      );
    }
  });
}

Iterable<String> _activeSkus(LevelDef level) {
  final Set<String> skus = <String>{};
  for (final CompartmentDef compartment in level.compartments) {
    skus.addAll(compartment.cells.whereType<String>());
    skus.addAll(compartment.hidden);
  }
  for (final lane in level.movingLanes) {
    skus.addAll(lane.queue.map((product) => product.skuId));
  }
  skus.addAll(level.objective.targetCounts.keys);
  return skus;
}

Future<LevelPack> _verticalSlicePack() async {
  final String raw = await File(
    'assets/data/bundled/level_pack_vertical_slice.json',
  ).readAsString();
  return LevelPack.fromJson(jsonDecode(raw) as Map<String, Object?>);
}

Future<ProductCatalog> _productCatalog() async {
  final String raw = await File(
    'assets/data/bundled/product_catalog.json',
  ).readAsString();
  return ProductCatalog.fromJson(jsonDecode(raw) as Map<String, Object?>);
}

int _visibleProductCount(LevelDef level) {
  return level.compartments.fold<int>(0, (
    int count,
    CompartmentDef compartment,
  ) {
    return count + compartment.cells.whereType<String>().length;
  });
}

Map<String, int> _skuCounts(LevelDef level) {
  final Map<String, int> counts = <String, int>{};
  for (final CompartmentDef compartment in level.compartments) {
    for (final String skuId in compartment.cells.whereType<String>()) {
      counts[skuId] = (counts[skuId] ?? 0) + 1;
    }
  }
  return counts;
}
