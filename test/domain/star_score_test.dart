import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/domain/blockers/blocker_def.dart';
import 'package:shelf_rush_sort/domain/content/level_def.dart';
import 'package:shelf_rush_sort/domain/game/objective.dart';
import 'package:shelf_rush_sort/domain/game/star_score.dart';

void main() {
  // 6 initial products -> derived par of 2 moves.
  final LevelDef level = _sixProductLevel();

  test('three stars at or below par', () {
    expect(starsForLevel(moveCount: 1, level: level), 3);
    expect(starsForLevel(moveCount: 2, level: level), 3);
  });

  test('two stars within the half-par slack', () {
    expect(starsForLevel(moveCount: 3, level: level), 2);
  });

  test('one star when well over par', () {
    expect(starsForLevel(moveCount: 4, level: level), 1);
    expect(starsForLevel(moveCount: 9, level: level), 1);
  });

  test('authored score thresholds override the heuristic (P1.7)', () {
    final LevelDef scored = _scoredLevel();
    expect(starsForLevel(moveCount: 5, level: scored), 3);
    expect(starsForLevel(moveCount: 6, level: scored), 2);
    expect(starsForLevel(moveCount: 8, level: scored), 2);
    expect(starsForLevel(moveCount: 9, level: scored), 1);
  });

  test('blockers raise par so a clean run still earns three stars (P1.7)', () {
    final LevelDef blockerLevel = _blockerLevel();
    // Same move count, harder level: the blocker raises par by one, so the
    // run that earns 2 stars on the plain level earns 3 on the blocker level.
    expect(starsForLevel(moveCount: 3, level: level), 2);
    expect(starsForLevel(moveCount: 3, level: blockerLevel), 3);
  });
}

LevelDef _sixProductLevel() {
  return LevelDef(
    id: 'star_score_test',
    levelNumber: 1,
    title: 'Star Score Test',
    seed: 1,
    objective: ObjectiveRequirement(type: ObjectiveType.clearAll),
    compartments: <CompartmentDef>[
      CompartmentDef(
        index: 0,
        cells: const <String?>['sku_000', 'sku_000', null],
      ),
      CompartmentDef(
        index: 1,
        cells: const <String?>['sku_000', 'sku_001', 'sku_001'],
      ),
      CompartmentDef(index: 2, cells: const <String?>['sku_001', null, null]),
      for (var index = 3; index < 15; index += 1)
        CompartmentDef(
          index: index,
          locked: true,
          cells: const <String?>[null, null, null],
        ),
    ],
  );
}

LevelDef _scoredLevel() {
  // Heuristic par here would be tiny, so authored thresholds clearly override.
  return LevelDef(
    id: 'star_score_authored_test',
    levelNumber: 2,
    title: 'Authored Score',
    seed: 2,
    objective: ObjectiveRequirement(type: ObjectiveType.clearAll),
    score: const LevelScore(threeStarMoves: 5, twoStarMoves: 8),
    compartments: <CompartmentDef>[
      CompartmentDef(
        index: 0,
        cells: const <String?>['sku_000', 'sku_000', null],
      ),
      for (var index = 1; index < 15; index += 1)
        CompartmentDef(index: index, cells: const <String?>[null, null, null]),
    ],
  );
}

LevelDef _blockerLevel() {
  // Same 6 products as _sixProductLevel (par 2) plus one blocker -> par 3.
  return LevelDef(
    id: 'star_score_blocker_test',
    levelNumber: 3,
    title: 'Blocker Par',
    seed: 3,
    objective: ObjectiveRequirement(type: ObjectiveType.clearAll),
    compartments: <CompartmentDef>[
      CompartmentDef(
        index: 0,
        cells: const <String?>['sku_000', 'sku_000', null],
        cellBlockers: const <BlockerKind>[
          BlockerKind.frozen,
          BlockerKind.none,
          BlockerKind.none,
        ],
      ),
      CompartmentDef(
        index: 1,
        cells: const <String?>['sku_000', 'sku_001', 'sku_001'],
      ),
      CompartmentDef(index: 2, cells: const <String?>['sku_001', null, null]),
      for (var index = 3; index < 15; index += 1)
        CompartmentDef(
          index: index,
          locked: true,
          cells: const <String?>[null, null, null],
        ),
    ],
  );
}
