import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/domain/blockers/blocker_def.dart';
import 'package:shelf_rush_sort/domain/content/level_def.dart';
import 'package:shelf_rush_sort/domain/core/value_objects.dart';
import 'package:shelf_rush_sort/domain/game/board_rules.dart';
import 'package:shelf_rush_sort/domain/game/move.dart';

void main() {
  test('level 1 uses the full dense tutorial rack', () async {
    final LevelPack pack = await _verticalSlicePack();
    final LevelDef level = pack.levelByNumber(1);

    expect(level.compartments, hasLength(compartmentCount));
    expect(
      level.compartments.where((compartment) => compartment.locked),
      isEmpty,
    );
    expect(
      level.compartments.where((compartment) => compartment.decorative),
      isEmpty,
    );
    expect(_visibleProductCount(level), 36);
    expect(_emptyCellCount(level), 9);
    expect(_skuCounts(level).values, everyElement(6));
    expect(_skuCounts(level), hasLength(6));
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

  test('level 1 first hinted move completes a triple', () async {
    final LevelDef level = (await _verticalSlicePack()).levelByNumber(1);
    const BoardRules rules = BoardRules();
    final result = rules.applyMove(
      level.createBoardState(),
      MoveAction(
        source: CellAddress.fromCompartmentIndex(6, 0),
        target: CellAddress.fromCompartmentIndex(0, 2),
      ),
    );

    expect(result.isValid, isTrue);
    expect(result.clearedTriples, hasLength(1));
    expect(result.clearedTriples.single.skuId, 'sku_000');
  });

  test('levels 1-15 keep every rack compartment playable', () async {
    final LevelPack pack = await _verticalSlicePack();
    for (var levelNumber = 1; levelNumber <= 15; levelNumber += 1) {
      final LevelDef level = pack.levelByNumber(levelNumber);
      expect(
        level.compartments.where((compartment) {
          return !compartment.locked && !compartment.decorative;
        }),
        hasLength(compartmentCount),
        reason: 'level $levelNumber must use all compartments',
      );
      expect(
        level.compartments.where((compartment) => compartment.locked),
        isEmpty,
        reason: 'level $levelNumber must not use generic locks',
      );
      expect(
        level.compartments.where((compartment) => compartment.decorative),
        isEmpty,
        reason: 'level $levelNumber must not use decorative logical slots',
      );
    }
  });
}

Future<LevelPack> _verticalSlicePack() async {
  final String raw = await File(
    'assets/data/bundled/level_pack_vertical_slice.json',
  ).readAsString();
  return LevelPack.fromJson(jsonDecode(raw) as Map<String, Object?>);
}

int _visibleProductCount(LevelDef level) {
  return level.compartments.fold<int>(0, (
    int count,
    CompartmentDef compartment,
  ) {
    return count + compartment.cells.whereType<String>().length;
  });
}

int _emptyCellCount(LevelDef level) {
  return frontCellCount - _visibleProductCount(level);
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
