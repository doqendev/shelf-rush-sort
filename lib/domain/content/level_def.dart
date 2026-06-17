import '../core/value_objects.dart';
import '../game/board_state.dart';
import '../game/objective.dart';
import '../moving_lanes/moving_lane_def.dart';

final class CompartmentDef {
  CompartmentDef({
    required this.index,
    required List<SkuId?> cells,
    List<SkuId> hidden = const <SkuId>[],
    this.locked = false,
    this.decorative = false,
  }) : assert(cells.length == cellsPerCompartment),
       cells = List<SkuId?>.unmodifiable(cells),
       hidden = List<SkuId>.unmodifiable(hidden);

  factory CompartmentDef.fromJson(Map<String, Object?> json) {
    final List<Object?> cellsJson = json['cells']! as List<Object?>;
    final List<Object?> hiddenJson =
        json['hidden'] as List<Object?>? ?? const <Object?>[];
    return CompartmentDef(
      index: json['index']! as int,
      cells: cellsJson.map((Object? item) => item as String?).toList(),
      hidden: hiddenJson.cast<String>(),
      locked: json['locked'] as bool? ?? false,
      decorative: json['decorative'] as bool? ?? false,
    );
  }

  final int index;
  final List<SkuId?> cells;
  final List<SkuId> hidden;
  final bool locked;
  final bool decorative;
}

final class LevelDef {
  LevelDef({
    required this.id,
    required this.levelNumber,
    required this.title,
    required this.seed,
    required this.objective,
    required List<CompartmentDef> compartments,
    List<MovingLaneDef> movingLanes = const <MovingLaneDef>[],
    this.timeLimitSeconds,
    this.moveLimit,
    this.difficulty = 'normal',
  }) : compartments = List<CompartmentDef>.unmodifiable(compartments),
       movingLanes = List<MovingLaneDef>.unmodifiable(movingLanes);

  factory LevelDef.fromJson(Map<String, Object?> json) {
    final List<Object?> compartmentsJson =
        json['compartments']! as List<Object?>;
    final List<Object?> movingLanesJson =
        json['movingLanes'] as List<Object?>? ?? const <Object?>[];
    final Map<String, Object?> objectiveJson =
        json['objective']! as Map<String, Object?>;
    final Map<String, Object?> targetCountsJson =
        objectiveJson['targetCounts'] as Map<String, Object?>? ??
        const <String, Object?>{};
    return LevelDef(
      id: json['id']! as String,
      levelNumber: json['levelNumber']! as int,
      title: json['title']! as String,
      seed: json['seed']! as int,
      timeLimitSeconds: json['timeLimitSeconds'] as int?,
      moveLimit: json['moveLimit'] as int?,
      difficulty: json['difficulty'] as String? ?? 'normal',
      objective: ObjectiveRequirement(
        type: ObjectiveType.values.byName(objectiveJson['type']! as String),
        targetCounts: <SkuId, int>{
          for (final MapEntry<String, Object?> entry
              in targetCountsJson.entries)
            entry.key: entry.value! as int,
        },
      ),
      compartments: compartmentsJson
          .map((Object? item) {
            return CompartmentDef.fromJson(item! as Map<String, Object?>);
          })
          .toList(growable: false),
      movingLanes: movingLanesJson
          .map((Object? item) {
            return MovingLaneDef.fromJson(item! as Map<String, Object?>);
          })
          .toList(growable: false),
    );
  }

  final LevelId id;
  final int levelNumber;
  final String title;
  final int seed;
  final ObjectiveRequirement objective;
  final List<CompartmentDef> compartments;
  final List<MovingLaneDef> movingLanes;
  final int? timeLimitSeconds;
  final int? moveLimit;
  final String difficulty;

  BoardState createBoardState() {
    var instanceCounter = 0;
    ProductInstance nextProduct(SkuId skuId) {
      instanceCounter += 1;
      return ProductInstance(id: '${id}_p_$instanceCounter', skuId: skuId);
    }

    final List<CompartmentState> states = compartments
        .map((CompartmentDef compartment) {
          return CompartmentState(
            index: compartment.index,
            locked: compartment.locked,
            decorative: compartment.decorative,
            frontCells: compartment.cells
                .map((SkuId? skuId) {
                  if (skuId == null) {
                    return const ShelfCell.empty();
                  }
                  return ShelfCell(product: nextProduct(skuId));
                })
                .toList(growable: false),
            hiddenStack: compartment.hidden
                .map(nextProduct)
                .toList(growable: false),
          );
        })
        .toList(growable: false);
    return BoardState(levelId: id, compartments: states);
  }
}

final class LevelPack {
  LevelPack({
    required this.id,
    required this.version,
    required List<LevelDef> levels,
  }) : levels = List<LevelDef>.unmodifiable(levels);

  factory LevelPack.fromJson(Map<String, Object?> json) {
    final List<Object?> levelJson = json['levels']! as List<Object?>;
    return LevelPack(
      id: json['id']! as String,
      version: json['version']! as int,
      levels: levelJson
          .map((Object? item) {
            return LevelDef.fromJson(item! as Map<String, Object?>);
          })
          .toList(growable: false),
    );
  }

  final String id;
  final int version;
  final List<LevelDef> levels;

  LevelDef levelByNumber(int number) {
    return levels.firstWhere((LevelDef level) => level.levelNumber == number);
  }
}
