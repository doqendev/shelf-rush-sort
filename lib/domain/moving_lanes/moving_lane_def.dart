import '../core/value_objects.dart';

enum LaneOrientation { horizontal, vertical }

enum LaneBehavior { loop, finite }

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
  }) : queue = List<MovingLaneProductDef>.unmodifiable(queue);

  factory MovingLaneDef.fromJson(Map<String, Object?> json) {
    final String orientationName = json['orientation']! as String;
    final String behaviorName = json['behavior']! as String;
    final List<Object?> queueJson = json['queue']! as List<Object?>;
    return MovingLaneDef(
      id: json['id']! as String,
      orientation: LaneOrientation.values.byName(orientationName),
      behavior: LaneBehavior.values.byName(behaviorName),
      speedCellsPerSecond: (json['speedCellsPerSecond']! as num).toDouble(),
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

  bool get isEmpty => queue.isEmpty;
}
