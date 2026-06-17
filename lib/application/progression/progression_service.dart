import '../../domain/content/level_def.dart';
import '../../infrastructure/save/save_repository.dart';

final class ProgressionService {
  const ProgressionService();

  PlayerSave onLevelWon(PlayerSave save, LevelDef level) {
    if (level.levelNumber <= save.highestLevelCompleted) {
      return save;
    }
    return save.copyWith(
      highestLevelCompleted: level.levelNumber,
      lastSeenAt: DateTime.now().toUtc(),
    );
  }
}
