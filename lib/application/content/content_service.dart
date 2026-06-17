import '../../domain/content/economy_def.dart';
import '../../domain/content/level_def.dart';
import '../../domain/content/product_def.dart';
import '../../domain/content/product_visual_def.dart';
import '../../domain/content/remote_config_def.dart';
import '../../domain/content/theme_def.dart';

final class GameContent {
  const GameContent({
    required this.productCatalog,
    required this.levelPack,
    required this.economy,
    required this.remoteConfig,
    required this.themes,
    required this.eventCatalog,
    required this.productVisualManifest,
  });

  final ProductCatalog productCatalog;
  final LevelPack levelPack;
  final EconomyDef economy;
  final RemoteConfigDef remoteConfig;
  final List<ThemeDef> themes;
  final Map<String, Object?> eventCatalog;
  final ProductVisualManifest productVisualManifest;
}

abstract interface class ContentService {
  GameContent get content;

  LevelDef levelByNumber(int number);
}

final class InMemoryContentService implements ContentService {
  const InMemoryContentService(this.content);

  @override
  final GameContent content;

  @override
  LevelDef levelByNumber(int number) {
    return content.levelPack.levelByNumber(number);
  }
}
