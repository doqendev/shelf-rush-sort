import '../../domain/content/level_def.dart';

final class ContentVersionService {
  const ContentVersionService();

  bool isCompatible({
    required LevelPack levelPack,
    required String saveLevelPackId,
    required int saveLevelPackVersion,
  }) {
    return levelPack.id == saveLevelPackId &&
        levelPack.version >= saveLevelPackVersion;
  }
}
