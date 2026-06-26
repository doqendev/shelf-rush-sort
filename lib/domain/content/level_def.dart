import '../blockers/blocker_def.dart';
import '../core/value_objects.dart';
import '../game/board_state.dart';
import '../game/hidden_preview.dart';
import '../game/objective.dart';
import '../moving_lanes/moving_lane_def.dart';

export '../game/hidden_preview.dart';

enum CompartmentRole { standard, reserve, support, decorative }

enum LevelTag { tutorial, normal, hard, superHard, generated, humanReviewed }

final class HiddenLayerDef {
  HiddenLayerDef({
    required List<SkuId?> cells,
    this.previewMode = HiddenPreviewMode.exactDim,
  }) : assert(cells.length == cellsPerCompartment),
       cells = List<SkuId?>.unmodifiable(cells);

  factory HiddenLayerDef.fromJson(Map<String, Object?> json) {
    final List<Object?> cellsJson = json['cells']! as List<Object?>;
    return HiddenLayerDef(
      cells: cellsJson.map((Object? item) => item as String?).toList(),
      previewMode: HiddenPreviewMode.values.byName(
        json['previewMode'] as String? ?? HiddenPreviewMode.exactDim.name,
      ),
    );
  }

  final List<SkuId?> cells;
  final HiddenPreviewMode previewMode;
}

final class LevelRulesDef {
  const LevelRulesDef({
    this.allowSameCompartmentMoves = false,
    this.allowSwap = false,
    this.allowCategoryClears = false,
  });

  factory LevelRulesDef.fromJson(Map<String, Object?> json) {
    return LevelRulesDef(
      allowSameCompartmentMoves:
          json['allowSameCompartmentMoves'] as bool? ?? false,
      allowSwap: json['allowSwap'] as bool? ?? false,
      allowCategoryClears: json['allowCategoryClears'] as bool? ?? false,
    );
  }

  final bool allowSameCompartmentMoves;
  final bool allowSwap;
  final bool allowCategoryClears;
}

final class HumanReviewMetadata {
  const HumanReviewMetadata({
    required this.author,
    required this.intent,
    required this.curriculumTag,
    required this.difficultyTarget,
    required this.humanReviewGrade,
  });

  factory HumanReviewMetadata.fromJson(Map<String, Object?> json) {
    return HumanReviewMetadata(
      author: json['author'] as String? ?? 'unreviewed',
      intent: json['intent'] as String? ?? '',
      curriculumTag: json['curriculumTag'] as String? ?? '',
      difficultyTarget: json['difficultyTarget'] as String? ?? '',
      humanReviewGrade: json['humanReviewGrade'] as String? ?? 'unreviewed',
    );
  }

  final String author;
  final String intent;
  final String curriculumTag;
  final String difficultyTarget;
  final String humanReviewGrade;
}

final class ValidationMetrics {
  const ValidationMetrics({this.values = const <String, Object?>{}});

  factory ValidationMetrics.fromJson(Map<String, Object?> json) {
    return ValidationMetrics(values: json);
  }

  final Map<String, Object?> values;
}

final class LaneFailurePolicy {
  const LaneFailurePolicy({this.failOnRequiredMiss = true, this.allowedMisses});

  factory LaneFailurePolicy.fromJson(Map<String, Object?> json) {
    return LaneFailurePolicy(
      failOnRequiredMiss: json['failOnRequiredMiss'] as bool? ?? true,
      allowedMisses: json['allowedMisses'] as int?,
    );
  }

  final bool failOnRequiredMiss;
  final int? allowedMisses;
}

final class CompartmentDef {
  CompartmentDef({
    required this.index,
    required List<SkuId?> cells,
    List<BlockerKind>? cellBlockers,
    List<BlockerKind>? productBlockers,
    List<SkuId> hidden = const <SkuId>[],
    List<HiddenLayerDef>? hiddenLayers,
    this.locked = false,
    this.decorative = false,
    this.role = CompartmentRole.standard,
  }) : assert(cells.length == cellsPerCompartment),
       assert(
         cellBlockers == null || cellBlockers.length == cellsPerCompartment,
       ),
       assert(
         productBlockers == null ||
             productBlockers.length == cellsPerCompartment,
       ),
       cells = List<SkuId?>.unmodifiable(cells),
       cellBlockers = List<BlockerKind>.unmodifiable(
         cellBlockers ??
             List<BlockerKind>.filled(cellsPerCompartment, BlockerKind.none),
       ),
       productBlockers = List<BlockerKind>.unmodifiable(
         productBlockers ??
             List<BlockerKind>.filled(cellsPerCompartment, BlockerKind.none),
       ),
       hidden = List<SkuId>.unmodifiable(
         hidden.isEmpty && hiddenLayers != null
             ? _flattenHiddenLayers(hiddenLayers)
             : hidden,
       ),
       hiddenLayers = List<HiddenLayerDef>.unmodifiable(
         hiddenLayers ?? _hiddenLayersFromFlat(hidden),
       );

  factory CompartmentDef.fromJson(Map<String, Object?> json) {
    final List<Object?> cellsJson = json['cells']! as List<Object?>;
    final List<Object?> hiddenJson =
        json['hidden'] as List<Object?>? ?? const <Object?>[];
    final List<Object?> hiddenLayersJson =
        json['hiddenLayers'] as List<Object?>? ?? const <Object?>[];
    final List<Object?> cellBlockersJson =
        json['cellBlockers'] as List<Object?>? ?? const <Object?>[];
    final List<Object?> productBlockersJson =
        json['productBlockers'] as List<Object?>? ?? const <Object?>[];
    final List<HiddenLayerDef> parsedHiddenLayers = hiddenLayersJson
        .map((Object? item) {
          return HiddenLayerDef.fromJson(item! as Map<String, Object?>);
        })
        .toList(growable: false);
    return CompartmentDef(
      index: json['index']! as int,
      cells: cellsJson.map((Object? item) => item as String?).toList(),
      cellBlockers: _parseBlockers(cellBlockersJson),
      productBlockers: _parseBlockers(productBlockersJson),
      hidden: hiddenJson.cast<String>(),
      hiddenLayers: parsedHiddenLayers.isEmpty ? null : parsedHiddenLayers,
      locked: json['locked'] as bool? ?? false,
      decorative: json['decorative'] as bool? ?? false,
      role: CompartmentRole.values.byName(
        json['role'] as String? ?? CompartmentRole.standard.name,
      ),
    );
  }

  final int index;
  final List<SkuId?> cells;
  final List<BlockerKind> cellBlockers;
  final List<BlockerKind> productBlockers;
  final List<SkuId> hidden;
  final List<HiddenLayerDef> hiddenLayers;
  final bool locked;
  final bool decorative;
  final CompartmentRole role;

  static List<SkuId> _flattenHiddenLayers(List<HiddenLayerDef> layers) {
    return layers
        .expand((HiddenLayerDef layer) => layer.cells)
        .whereType<SkuId>()
        .toList(growable: false);
  }

  static List<HiddenLayerDef> _hiddenLayersFromFlat(List<SkuId> hidden) {
    if (hidden.isEmpty) {
      return const <HiddenLayerDef>[];
    }
    final List<HiddenLayerDef> layers = <HiddenLayerDef>[];
    for (var index = 0; index < hidden.length; index += cellsPerCompartment) {
      final List<SkuId?> cells = <SkuId?>[
        for (var cell = 0; cell < cellsPerCompartment; cell += 1)
          index + cell < hidden.length ? hidden[index + cell] : null,
      ];
      layers.add(HiddenLayerDef(cells: cells));
    }
    return layers;
  }

  static List<BlockerKind>? _parseBlockers(List<Object?> json) {
    if (json.isEmpty) {
      return null;
    }
    return json
        .map((Object? item) {
          return BlockerKind.values.byName(
            item as String? ?? BlockerKind.none.name,
          );
        })
        .toList(growable: false);
  }
}

/// Per-level star thresholds (third-pass audit P1.7). When present, stars are
/// awarded from these authored move counts instead of the generic par
/// heuristic — intended to be seeded from solver minimum moves and human-tuned.
final class LevelScore {
  const LevelScore({required this.threeStarMoves, required this.twoStarMoves});

  factory LevelScore.fromJson(Map<String, Object?> json) {
    return LevelScore(
      threeStarMoves: json['threeStarMoves']! as int,
      twoStarMoves: json['twoStarMoves']! as int,
    );
  }

  final int threeStarMoves;
  final int twoStarMoves;
}

/// A short player-facing lesson shown when a level opens, teaching the one new
/// mental model the level introduces. The curriculum carried human-written
/// intent metadata, but the player only ever saw the generic objective line;
/// this surfaces the lesson in the UI (hands-on v3 P1.2).
final class LevelTeachingCopy {
  const LevelTeachingCopy({required this.headline, required this.body});

  factory LevelTeachingCopy.fromJson(Map<String, Object?> json) {
    return LevelTeachingCopy(
      headline: json['headline']! as String,
      body: json['body']! as String,
    );
  }

  final String headline;
  final String body;
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
    this.rules = const LevelRulesDef(),
    List<LevelTag> tags = const <LevelTag>[],
    this.humanReview,
    this.validationMetrics = const ValidationMetrics(),
    this.laneFailurePolicy = const LaneFailurePolicy(),
    this.score,
    this.tutorialCopy,
  }) : compartments = List<CompartmentDef>.unmodifiable(compartments),
       movingLanes = List<MovingLaneDef>.unmodifiable(movingLanes),
       tags = List<LevelTag>.unmodifiable(tags);

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
    final Map<String, Object?> categoryTargetsJson =
        objectiveJson['categoryTargets'] as Map<String, Object?>? ??
        const <String, Object?>{};
    final Map<String, Object?> specialTargetsJson =
        objectiveJson['specialTargets'] as Map<String, Object?>? ??
        const <String, Object?>{};
    final List<Object?> tagsJson =
        json['tags'] as List<Object?>? ?? const <Object?>[];
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
        categoryTargets: <String, int>{
          for (final MapEntry<String, Object?> entry
              in categoryTargetsJson.entries)
            entry.key: entry.value! as int,
        },
        specialTargets: <String, int>{
          for (final MapEntry<String, Object?> entry
              in specialTargetsJson.entries)
            entry.key: entry.value! as int,
        },
        comboTarget: objectiveJson['comboTarget'] as int? ?? 0,
        laneDeliveryTarget: objectiveJson['laneDeliveryTarget'] as int? ?? 0,
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
      rules: LevelRulesDef.fromJson(
        json['rules'] as Map<String, Object?>? ?? const <String, Object?>{},
      ),
      tags: tagsJson
          .map((Object? item) => LevelTag.values.byName(item! as String))
          .toList(growable: false),
      humanReview: json['humanReview'] == null
          ? null
          : HumanReviewMetadata.fromJson(
              json['humanReview']! as Map<String, Object?>,
            ),
      validationMetrics: ValidationMetrics.fromJson(
        json['validationMetrics'] as Map<String, Object?>? ??
            const <String, Object?>{},
      ),
      laneFailurePolicy: LaneFailurePolicy.fromJson(
        json['laneFailurePolicy'] as Map<String, Object?>? ??
            const <String, Object?>{},
      ),
      score: json['score'] == null
          ? null
          : LevelScore.fromJson(json['score']! as Map<String, Object?>),
      tutorialCopy: json['tutorialCopy'] == null
          ? null
          : LevelTeachingCopy.fromJson(
              json['tutorialCopy']! as Map<String, Object?>,
            ),
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
  final LevelRulesDef rules;
  final List<LevelTag> tags;
  final HumanReviewMetadata? humanReview;
  final ValidationMetrics validationMetrics;
  final LaneFailurePolicy laneFailurePolicy;
  final LevelScore? score;
  final LevelTeachingCopy? tutorialCopy;

  BoardState createBoardState() {
    var instanceCounter = 0;
    ProductInstance nextProduct(SkuId skuId) {
      instanceCounter += 1;
      return ProductInstance(id: '${id}_p_$instanceCounter', skuId: skuId);
    }

    final List<CompartmentState> states = compartments
        .map((CompartmentDef compartment) {
          final List<HiddenPreviewLayerState> hiddenPreviewLayers = compartment
              .hiddenLayers
              .map((HiddenLayerDef layer) {
                return HiddenPreviewLayerState(
                  cells: layer.cells,
                  previewMode: layer.previewMode,
                );
              })
              .toList(growable: false);
          return CompartmentState(
            index: compartment.index,
            locked: compartment.locked,
            decorative: compartment.decorative,
            frontCells: <ShelfCell>[
              for (
                var cellIndex = 0;
                cellIndex < cellsPerCompartment;
                cellIndex += 1
              )
                () {
                  final SkuId? skuId = compartment.cells[cellIndex];
                  final BlockerKind cellBlocker =
                      compartment.cellBlockers[cellIndex];
                  final BlockerKind productBlocker =
                      compartment.productBlockers[cellIndex];
                  if (skuId == null) {
                    return ShelfCell.empty(blocker: cellBlocker);
                  }
                  return ShelfCell(
                    product: nextProduct(
                      skuId,
                    ).copyWith(blocker: productBlocker),
                    blocker: cellBlocker,
                  );
                }(),
            ],
            hiddenStack: compartment.hidden
                .map(nextProduct)
                .toList(growable: false),
            hiddenPreviewLayers: hiddenPreviewLayers,
            hiddenPreviewRevealed:
                hiddenPreviewLayers.isNotEmpty &&
                hiddenPreviewLayers.first.previewMode ==
                    HiddenPreviewMode.exactDim,
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
