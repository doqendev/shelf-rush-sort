import '../../domain/content/level_def.dart';
import '../../domain/content/remote_config_def.dart';
import '../../domain/moving_lanes/moving_lane_def.dart';

final class RemoteConfigService {
  const RemoteConfigService(this.defaults);

  final RemoteConfigDef defaults;

  bool isEnabled(String flag) => defaults.featureFlags[flag] ?? false;

  LevelDef applyToLevel(LevelDef level) {
    if (defaults.laneSpeedMultiplier == 1.0 || level.movingLanes.isEmpty) {
      return level;
    }
    return LevelDef(
      id: level.id,
      levelNumber: level.levelNumber,
      title: level.title,
      seed: level.seed,
      objective: level.objective,
      compartments: level.compartments,
      movingLanes: level.movingLanes
          .map((MovingLaneDef lane) {
            return MovingLaneDef(
              id: lane.id,
              orientation: lane.orientation,
              behavior: lane.behavior,
              speedCellsPerSecond:
                  lane.speedCellsPerSecond * defaults.laneSpeedMultiplier,
              queue: lane.queue,
            );
          })
          .toList(growable: false),
      timeLimitSeconds: level.timeLimitSeconds,
      moveLimit: level.moveLimit,
      difficulty: level.difficulty,
    );
  }
}
