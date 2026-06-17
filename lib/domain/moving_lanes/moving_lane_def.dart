import '../core/value_objects.dart';

enum LaneOrientation { horizontal, vertical }

enum LaneBehavior { loop, finite }

enum LaneAnchor { bottom, top, left, right, rowOverlay, columnOverlay }

final class MovingLaneProductDef {
  const MovingLaneProductDef({required this.skuId, required this.travelTimeMs});

  factory MovingLaneProductDef.fromJson(Map<String, Object?> json) {
    return MovingLaneProductDef(
      skuId: json['skuId']! as String,
      travelTimeMs: json['travelTimeMs']! as int,
    );
  }

  final SkuId skuId;
  final int travelTimeMs;

  Map<String, Object?> toJson() {
    return <String, Object?>{'skuId': skuId, 'travelTimeMs': travelTimeMs};
  }
}

final class MovingLaneDef {
  MovingLaneDef({
    required this.id,
    required this.orientation,
    required this.behavior,
    required this.speedCellsPerSecond,
    required List<MovingLaneProductDef> queue,
    LaneAnchor? anchor,
    this.row,
    this.column,
    this.visibleWindowCells = 4,
    this.loopsMissedProducts = false,
    this.maxMisses,
    this.requiredForObjective = false,
  }) : anchor = anchor ?? _defaultAnchorFor(orientation),
       queue = List<MovingLaneProductDef>.unmodifiable(queue);

  factory MovingLaneDef.fromJson(Map<String, Object?> json) {
    final String orientationName = json['orientation']! as String;
    final String behaviorName = json['behavior']! as String;
    final List<Object?> queueJson = json['queue']! as List<Object?>;
    final LaneOrientation orientation = LaneOrientation.values.byName(
      orientationName,
    );
    return MovingLaneDef(
      id: json['id']! as String,
      orientation: orientation,
      behavior: LaneBehavior.values.byName(behaviorName),
      speedCellsPerSecond: (json['speedCellsPerSecond']! as num).toDouble(),
      anchor: json['anchor'] == null
          ? _defaultAnchorFor(orientation)
          : LaneAnchor.values.byName(json['anchor']! as String),
      row: json['row'] as int?,
      column: json['column'] as int?,
      visibleWindowCells: (json['visibleWindowCells'] as num?)?.toDouble() ?? 4,
      loopsMissedProducts: json['loopsMissedProducts'] as bool? ?? false,
      maxMisses: json['maxMisses'] as int?,
      requiredForObjective: json['requiredForObjective'] as bool? ?? false,
      queue: queueJson
          .map((Object? item) {
            return MovingLaneProductDef.fromJson(item! as Map<String, Object?>);
          })
          .toList(growable: false),
    );
  }

  final String id;
  final LaneOrientation orientation;
  final LaneBehavior behavior;
  final double speedCellsPerSecond;
  final List<MovingLaneProductDef> queue;
  final LaneAnchor anchor;
  final int? row;
  final int? column;
  final double visibleWindowCells;
  final bool loopsMissedProducts;
  final int? maxMisses;
  final bool requiredForObjective;

  bool get isEmpty => queue.isEmpty;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'orientation': orientation.name,
      'behavior': behavior.name,
      'speedCellsPerSecond': speedCellsPerSecond,
      'anchor': anchor.name,
      if (row != null) 'row': row,
      if (column != null) 'column': column,
      'visibleWindowCells': visibleWindowCells,
      'loopsMissedProducts': loopsMissedProducts,
      if (maxMisses != null) 'maxMisses': maxMisses,
      'requiredForObjective': requiredForObjective,
      'queue': queue
          .map((MovingLaneProductDef product) => product.toJson())
          .toList(growable: false),
    };
  }

  static LaneAnchor _defaultAnchorFor(LaneOrientation orientation) {
    return switch (orientation) {
      LaneOrientation.horizontal => LaneAnchor.bottom,
      LaneOrientation.vertical => LaneAnchor.left,
    };
  }
}
