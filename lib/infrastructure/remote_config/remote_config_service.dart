import '../../domain/content/level_def.dart';
import '../../domain/content/remote_config_def.dart';
import '../../domain/moving_lanes/moving_lane_def.dart';

final class RemoteConfigService {
  const RemoteConfigService(this.defaults);

  final RemoteConfigDef defaults;

  bool isEnabled(String flag) => defaults.featureFlags[flag] ?? false;

  LevelDef applyToLevel(LevelDef level) {
    final bool laneNeutral =
        defaults.laneSpeedMultiplier == 1.0 || level.movingLanes.isEmpty;
    final bool timerNeutral =
        defaults.timerMultiplier == 1.0 || level.timeLimitSeconds == null;
    if (laneNeutral && timerNeutral) {
      return level;
    }
    return LevelDef(
      id: level.id,
      levelNumber: level.levelNumber,
      title: level.title,
      seed: level.seed,
      objective: level.objective,
      compartments: level.compartments,
      movingLanes: laneNeutral
          ? level.movingLanes
          : level.movingLanes
                .map((MovingLaneDef lane) {
                  return MovingLaneDef(
                    id: lane.id,
                    orientation: lane.orientation,
                    behavior: lane.behavior,
                    speedCellsPerSecond:
                        lane.speedCellsPerSecond * defaults.laneSpeedMultiplier,
                    queue: lane.queue,
                    anchor: lane.anchor,
                    row: lane.row,
                    column: lane.column,
                    visibleWindowCells: lane.visibleWindowCells,
                    loopsMissedProducts: lane.loopsMissedProducts,
                    maxMisses: lane.maxMisses,
                    requiredForObjective: lane.requiredForObjective,
                  );
                })
                .toList(growable: false),
      timeLimitSeconds: timerNeutral
          ? level.timeLimitSeconds
          : (level.timeLimitSeconds! * defaults.timerMultiplier).round(),
      moveLimit: level.moveLimit,
      difficulty: level.difficulty,
      rules: level.rules,
      tags: level.tags,
      humanReview: level.humanReview,
      validationMetrics: level.validationMetrics,
      laneFailurePolicy: level.laneFailurePolicy,
    );
  }

  String rescueForFailReason(String failReason) {
    if (defaults.failRescuePriority.contains(failReason)) {
      return failReason;
    }
    return defaults.failRescuePriority.isEmpty
        ? failReason
        : defaults.failRescuePriority.first;
  }
}
