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
import 'package:shelf_rush_sort/domain/game/objective.dart';
import 'package:shelf_rush_sort/domain/solver/solver.dart';
import 'package:shelf_rush_sort/domain/solver/validation_report.dart';

/// Levels 2..[curatedThrough] are the hand-authored Sprint B curriculum; the
/// rest of the opening pack still uses the full rack until curated too.
const int curatedThrough = 15;

void main() {
  test('a stacked hidden layer cascades: one move clears a chain', () {
    // The engagement engine: completing a front triple over a stacked hidden
    // layer reveals a full triple that auto-clears, which reveals the next, and
    // so on — one player move detonates a multi-clear cascade (the dopamine
    // hit) while staying trivial to play and cheap for the solver.
    const BoardRules rules = BoardRules();
    final LevelDef level = LevelDef(
      id: 'cascade_probe',
      levelNumber: 1,
      title: 'Cascade',
      seed: 1,
      objective: ObjectiveRequirement(type: ObjectiveType.clearAll),
      compartments: <CompartmentDef>[
        CompartmentDef(
          index: 0,
          cells: const <String?>['sku_000', 'sku_000', null],
          hidden: const <String>[
            'sku_001', 'sku_001', 'sku_001', //
            'sku_002', 'sku_002', 'sku_002', //
          ],
        ),
        CompartmentDef(index: 1, cells: const <String?>['sku_000', null, null]),
        for (var index = 2; index < compartmentCount; index += 1)
          CompartmentDef(
            index: index,
            cells: const <String?>[null, null, null],
          ),
      ],
    );
    final result = rules.applyMove(
      level.createBoardState(),
      MoveAction(
        source: CellAddress.fromCompartmentIndex(1, 0),
        target: CellAddress.fromCompartmentIndex(0, 2),
      ),
    );
    expect(result.isValid, isTrue);
    expect(
      result.clearedTriples.length,
      greaterThanOrEqualTo(3),
      reason: 'one move should cascade sku_000 -> sku_001 -> sku_002',
    );
    expect(result.comboCount, greaterThanOrEqualTo(3));
    expect(result.state.visibleProductCount, 0);
  });

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

  test('level 4 hidden-reveal sequence completes (v3 P0.2 regression)', () async {
    // The reviewer's QA run stalled in-browser after the first hidden-reveal
    // clear on level 4 (a CPU-render thread starvation in his no-WebGL sandbox).
    // This pins the exact reproduction move sequence to a clean completion so
    // the reveal path itself is proven correct in CI.
    final LevelDef level = (await _verticalSlicePack()).levelByNumber(4);
    const BoardRules rules = BoardRules();

    // Move 1: clear the front triple, which reveals the two hidden products.
    final r1 = rules.applyMove(
      level.createBoardState(),
      MoveAction(
        source: CellAddress.fromCompartmentIndex(1, 0),
        target: CellAddress.fromCompartmentIndex(0, 2),
      ),
    );
    expect(r1.isValid, isTrue);
    expect(r1.clearedTriples, hasLength(1));
    expect(
      r1.revealedProducts,
      hasLength(2),
      reason: 'clearing the front shelf must reveal the two hidden products',
    );

    // Move 2: complete one revealed triple.
    final r2 = rules.applyMove(
      r1.state,
      MoveAction(
        source: CellAddress.fromCompartmentIndex(0, 0),
        target: CellAddress.fromCompartmentIndex(1, 0),
      ),
    );
    expect(r2.isValid, isTrue);
    expect(r2.clearedTriples, hasLength(1));

    // Move 3: complete the last triple; the board is now empty.
    final r3 = rules.applyMove(
      r2.state,
      MoveAction(
        source: CellAddress.fromCompartmentIndex(0, 1),
        target: CellAddress.fromCompartmentIndex(2, 2),
      ),
    );
    expect(r3.isValid, isTrue);
    expect(r3.clearedTriples, hasLength(1));
    expect(
      r3.state.visibleProductCount,
      0,
      reason: 'level 4 completes through the hidden reveal without stalling',
    );
  });

  test(
    'mastery levels 11-15 complete via the documented bridge moves',
    () async {
      // These (compartment, cell, compartment, cell) sequences are exactly the
      // solution flows published in qa_manifest.json, so the reviewer's bridge
      // certification of 11-15 is guaranteed to reach a won board (v4 capture
      // review P1.2).
      final LevelPack pack = await _verticalSlicePack();
      const BoardRules rules = BoardRules();
      final Map<int, List<List<int>>> flows = <int, List<List<int>>>{
        11: <List<int>>[
          <int>[2, 2, 0, 2],
          <int>[3, 2, 1, 2],
          <int>[4, 0, 2, 2],
          <int>[4, 1, 3, 2],
        ],
        12: <List<int>>[
          <int>[1, 0, 0, 2],
          <int>[2, 0, 1, 0],
          <int>[3, 0, 2, 0],
        ],
        13: <List<int>>[
          <int>[1, 0, 0, 2],
          <int>[2, 0, 1, 0],
          <int>[3, 1, 2, 0],
          <int>[3, 0, 0, 2],
        ],
        14: <List<int>>[
          <int>[1, 0, 0, 2],
          <int>[2, 0, 1, 0],
          <int>[3, 2, 0, 2],
          <int>[2, 1, 3, 2],
        ],
        15: <List<int>>[
          <int>[1, 0, 0, 2],
          <int>[2, 0, 1, 0],
          <int>[3, 0, 2, 0],
          <int>[3, 1, 0, 2],
        ],
      };
      for (final MapEntry<int, List<List<int>>> entry in flows.entries) {
        final LevelDef level = pack.levelByNumber(entry.key);
        var board = level.createBoardState();
        for (final List<int> m in entry.value) {
          final result = rules.applyMove(
            board,
            MoveAction(
              source: CellAddress.fromCompartmentIndex(m[0], m[1]),
              target: CellAddress.fromCompartmentIndex(m[2], m[3]),
            ),
          );
          expect(
            result.isValid,
            isTrue,
            reason: 'level ${entry.key}: move $m must be valid',
          );
          board = result.state;
        }
        expect(
          board.visibleProductCount,
          0,
          reason: 'level ${entry.key} must complete via its documented moves',
        );
      }
    },
  );

  test(
    'curriculum levels 1-15 carry teaching copy + star thresholds (v3 P1.2)',
    () async {
      final LevelPack pack = await _verticalSlicePack();
      for (var levelNumber = 1; levelNumber <= 15; levelNumber += 1) {
        final LevelDef level = pack.levelByNumber(levelNumber);
        expect(
          level.tutorialCopy,
          isNotNull,
          reason: 'level $levelNumber needs a player-facing lesson',
        );
        expect(level.tutorialCopy!.headline, isNotEmpty);
        expect(level.tutorialCopy!.body, isNotEmpty);
        // P1.4: every curriculum level (including level 1) carries star
        // thresholds, so the bridge and map can treat them uniformly.
        expect(
          level.score,
          isNotNull,
          reason: 'level $levelNumber needs authored star thresholds',
        );
      }
    },
  );

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
      // P1.7: star thresholds are seeded from the solver optimum so 3 stars is
      // actually achievable. The generic par heuristic under-counts staging and
      // blocker moves and can make 3 stars impossible; the seeded threshold must
      // equal the live solver minimum so it never drifts out of sync.
      expect(
        level.score,
        isNotNull,
        reason: 'level $levelNumber needs seeded star thresholds',
      );
      expect(
        level.score!.threeStarMoves,
        metrics.minSolutionMoves,
        reason: 'level $levelNumber 3-star must equal the solver optimum',
      );
      expect(
        level.score!.twoStarMoves,
        greaterThan(level.score!.threeStarMoves),
        reason: 'level $levelNumber 2-star must exceed the 3-star threshold',
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
