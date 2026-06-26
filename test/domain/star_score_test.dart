import 'package:flutter_test/flutter_test.dart';
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
