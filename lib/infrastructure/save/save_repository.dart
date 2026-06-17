import 'dart:convert';

import '../../domain/boosters/booster_def.dart';

final class SaveProgress {
  const SaveProgress({
    required this.highestLevelCompleted,
    required this.currentChapterId,
    required this.stars,
    required this.xp,
    required this.winStreak,
  });

  factory SaveProgress.initial() {
    return const SaveProgress(
      highestLevelCompleted: 0,
      currentChapterId: 'market_intro',
      stars: 0,
      xp: 0,
      winStreak: 0,
    );
  }

  factory SaveProgress.fromJson(Map<String, Object?> json) {
    return SaveProgress(
      highestLevelCompleted: json['highestLevelCompleted']! as int,
      currentChapterId: json['currentChapterId']! as String,
      stars: json['stars']! as int,
      xp: json['xp']! as int,
      winStreak: json['winStreak']! as int,
    );
  }

  final int highestLevelCompleted;
  final String currentChapterId;
  final int stars;
  final int xp;
  final int winStreak;

  SaveProgress copyWith({
    int? highestLevelCompleted,
    String? currentChapterId,
    int? stars,
    int? xp,
    int? winStreak,
  }) {
    return SaveProgress(
      highestLevelCompleted:
          highestLevelCompleted ?? this.highestLevelCompleted,
      currentChapterId: currentChapterId ?? this.currentChapterId,
      stars: stars ?? this.stars,
      xp: xp ?? this.xp,
      winStreak: winStreak ?? this.winStreak,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'highestLevelCompleted': highestLevelCompleted,
      'currentChapterId': currentChapterId,
      'stars': stars,
      'xp': xp,
      'winStreak': winStreak,
    };
  }
}

final class SaveWallet {
  const SaveWallet({required this.coins});

  factory SaveWallet.fromJson(Map<String, Object?> json) {
    return SaveWallet(coins: json['coins']! as int);
  }

  final int coins;

  SaveWallet copyWith({int? coins}) {
    return SaveWallet(coins: coins ?? this.coins);
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{'coins': coins};
  }
}

final class SaveSettings {
  const SaveSettings({
    required this.inputMode,
    required this.music,
    required this.sfx,
    required this.haptics,
    required this.reduceMotion,
    required this.relaxModePreferred,
    required this.consentState,
  });

  factory SaveSettings.initial() {
    return const SaveSettings(
      inputMode: 'hybrid',
      music: true,
      sfx: true,
      haptics: true,
      reduceMotion: false,
      relaxModePreferred: false,
      consentState: 'unknown',
    );
  }

  factory SaveSettings.fromJson(Map<String, Object?> json) {
    return SaveSettings(
      inputMode: json['inputMode']! as String,
      music: json['music']! as bool,
      sfx: json['sfx']! as bool,
      haptics: json['haptics']! as bool,
      reduceMotion: json['reduceMotion']! as bool,
      relaxModePreferred: json['relaxModePreferred']! as bool,
      consentState: json['consentState']! as String,
    );
  }

  final String inputMode;
  final bool music;
  final bool sfx;
  final bool haptics;
  final bool reduceMotion;
  final bool relaxModePreferred;
  final String consentState;

  SaveSettings copyWith({
    String? inputMode,
    bool? music,
    bool? sfx,
    bool? haptics,
    bool? reduceMotion,
    bool? relaxModePreferred,
    String? consentState,
  }) {
    return SaveSettings(
      inputMode: inputMode ?? this.inputMode,
      music: music ?? this.music,
      sfx: sfx ?? this.sfx,
      haptics: haptics ?? this.haptics,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      relaxModePreferred: relaxModePreferred ?? this.relaxModePreferred,
      consentState: consentState ?? this.consentState,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'inputMode': inputMode,
      'music': music,
      'sfx': sfx,
      'haptics': haptics,
      'reduceMotion': reduceMotion,
      'relaxModePreferred': relaxModePreferred,
      'consentState': consentState,
    };
  }
}

final class SavePurchases {
  const SavePurchases({
    required this.removeAds,
    required this.starterPackPurchased,
  });

  factory SavePurchases.initial() {
    return const SavePurchases(removeAds: false, starterPackPurchased: false);
  }

  factory SavePurchases.fromJson(Map<String, Object?> json) {
    return SavePurchases(
      removeAds: json['removeAds']! as bool,
      starterPackPurchased: json['starterPackPurchased']! as bool,
    );
  }

  final bool removeAds;
  final bool starterPackPurchased;

  SavePurchases copyWith({bool? removeAds, bool? starterPackPurchased}) {
    return SavePurchases(
      removeAds: removeAds ?? this.removeAds,
      starterPackPurchased: starterPackPurchased ?? this.starterPackPurchased,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'removeAds': removeAds,
      'starterPackPurchased': starterPackPurchased,
    };
  }
}

final class SaveContentCompatibility {
  const SaveContentCompatibility({
    required this.levelPackId,
    required this.levelPackVersion,
  });

  factory SaveContentCompatibility.initial() {
    return const SaveContentCompatibility(
      levelPackId: 'pack_000_soft_launch_candidate',
      levelPackVersion: 1,
    );
  }

  factory SaveContentCompatibility.fromJson(Map<String, Object?> json) {
    return SaveContentCompatibility(
      levelPackId: json['levelPackId']! as String,
      levelPackVersion: json['levelPackVersion']! as int,
    );
  }

  final String levelPackId;
  final int levelPackVersion;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'levelPackId': levelPackId,
      'levelPackVersion': levelPackVersion,
    };
  }
}

final class PlayerSave {
  PlayerSave({
    required this.schemaVersion,
    required this.playerId,
    required this.createdAt,
    required this.lastSeenAt,
    required this.progress,
    required this.wallet,
    required Map<BoosterKind, int> boosters,
    required this.settings,
    required this.purchases,
    Map<String, Object?> collections = const <String, Object?>{},
    Map<String, Object?> events = const <String, Object?>{},
    Map<String, Object?> renovationState = const <String, Object?>{},
    Map<String, Object?> ledger = const <String, Object?>{},
    required this.contentCompatibility,
    this.checksum = '',
  }) : boosters = Map<BoosterKind, int>.unmodifiable(boosters),
       collections = Map<String, Object?>.unmodifiable(collections),
       events = Map<String, Object?>.unmodifiable(events),
       renovationState = Map<String, Object?>.unmodifiable(renovationState),
       ledger = Map<String, Object?>.unmodifiable(ledger);

  factory PlayerSave.newPlayer({
    required String playerId,
    required int startingCoins,
  }) {
    final DateTime now = DateTime.now().toUtc();
    return PlayerSave(
      schemaVersion: 1,
      playerId: playerId,
      createdAt: now,
      lastSeenAt: now,
      progress: SaveProgress.initial(),
      wallet: SaveWallet(coins: startingCoins),
      boosters: _initialBoosters(),
      settings: SaveSettings.initial(),
      purchases: SavePurchases.initial(),
      contentCompatibility: SaveContentCompatibility.initial(),
    ).withChecksum();
  }

  factory PlayerSave.fromJson(Map<String, Object?> json) {
    if (json.containsKey('progress')) {
      return PlayerSave._fromCurrentJson(json);
    }
    return PlayerSave._fromLegacyFlatJson(json).withChecksum();
  }

  factory PlayerSave._fromCurrentJson(Map<String, Object?> json) {
    final Map<String, Object?> boostersJson =
        json['boosters']! as Map<String, Object?>;
    return PlayerSave(
      schemaVersion: json['schemaVersion']! as int,
      playerId: json['playerId']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
      lastSeenAt: DateTime.parse(json['lastSeenAt']! as String),
      progress: SaveProgress.fromJson(
        json['progress']! as Map<String, Object?>,
      ),
      wallet: SaveWallet.fromJson(json['wallet']! as Map<String, Object?>),
      boosters: _boostersFromJson(boostersJson),
      settings: SaveSettings.fromJson(
        json['settings']! as Map<String, Object?>,
      ),
      purchases: SavePurchases.fromJson(
        json['purchases']! as Map<String, Object?>,
      ),
      collections:
          json['collections'] as Map<String, Object?>? ??
          const <String, Object?>{},
      events:
          json['events'] as Map<String, Object?>? ?? const <String, Object?>{},
      renovationState:
          json['renovationState'] as Map<String, Object?>? ??
          const <String, Object?>{},
      ledger:
          json['ledger'] as Map<String, Object?>? ?? const <String, Object?>{},
      contentCompatibility: SaveContentCompatibility.fromJson(
        json['contentCompatibility'] as Map<String, Object?>? ??
            SaveContentCompatibility.initial().toJson(),
      ),
      checksum: json['checksum'] as String? ?? '',
    );
  }

  factory PlayerSave._fromLegacyFlatJson(Map<String, Object?> json) {
    final Map<String, Object?> boostersJson =
        json['boosters']! as Map<String, Object?>;
    return PlayerSave(
      schemaVersion: json['schemaVersion']! as int,
      playerId: json['playerId']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
      lastSeenAt: DateTime.parse(json['lastSeenAt']! as String),
      progress: SaveProgress.initial().copyWith(
        highestLevelCompleted: json['highestLevelCompleted']! as int,
      ),
      wallet: SaveWallet(coins: json['coins']! as int),
      boosters: _boostersFromJson(boostersJson),
      settings: SaveSettings.initial().copyWith(
        music: json['music']! as bool,
        sfx: json['sfx']! as bool,
        haptics: json['haptics']! as bool,
        reduceMotion: json['reduceMotion']! as bool,
      ),
      purchases: SavePurchases.initial().copyWith(
        removeAds: json['removeAds']! as bool,
      ),
      contentCompatibility: SaveContentCompatibility.initial(),
      checksum: json['checksum'] as String? ?? '',
    );
  }

  final int schemaVersion;
  final String playerId;
  final DateTime createdAt;
  final DateTime lastSeenAt;
  final SaveProgress progress;
  final SaveWallet wallet;
  final Map<BoosterKind, int> boosters;
  final SaveSettings settings;
  final SavePurchases purchases;
  final Map<String, Object?> collections;
  final Map<String, Object?> events;
  final Map<String, Object?> renovationState;
  final Map<String, Object?> ledger;
  final SaveContentCompatibility contentCompatibility;
  final String checksum;

  int get highestLevelCompleted => progress.highestLevelCompleted;
  int get coins => wallet.coins;
  bool get music => settings.music;
  bool get sfx => settings.sfx;
  bool get haptics => settings.haptics;
  bool get reduceMotion => settings.reduceMotion;
  bool get removeAds => purchases.removeAds;

  bool get hasValidChecksum {
    return checksum == _calculateChecksum(toJson(includeChecksum: false));
  }

  PlayerSave copyWith({
    int? schemaVersion,
    DateTime? lastSeenAt,
    SaveProgress? progress,
    SaveWallet? wallet,
    Map<BoosterKind, int>? boosters,
    SaveSettings? settings,
    SavePurchases? purchases,
    Map<String, Object?>? collections,
    Map<String, Object?>? events,
    Map<String, Object?>? renovationState,
    Map<String, Object?>? ledger,
    SaveContentCompatibility? contentCompatibility,
    int? highestLevelCompleted,
    int? coins,
    bool? music,
    bool? sfx,
    bool? haptics,
    bool? reduceMotion,
    bool? removeAds,
    String? consentState,
  }) {
    final SaveProgress nextProgress = (progress ?? this.progress).copyWith(
      highestLevelCompleted: highestLevelCompleted,
    );
    final SaveWallet nextWallet = (wallet ?? this.wallet).copyWith(
      coins: coins,
    );
    final SaveSettings nextSettings = (settings ?? this.settings).copyWith(
      music: music,
      sfx: sfx,
      haptics: haptics,
      reduceMotion: reduceMotion,
      consentState: consentState,
    );
    final SavePurchases nextPurchases = (purchases ?? this.purchases).copyWith(
      removeAds: removeAds,
    );
    return PlayerSave(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      playerId: playerId,
      createdAt: createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      progress: nextProgress,
      wallet: nextWallet,
      boosters: boosters ?? this.boosters,
      settings: nextSettings,
      purchases: nextPurchases,
      collections: collections ?? this.collections,
      events: events ?? this.events,
      renovationState: renovationState ?? this.renovationState,
      ledger: ledger ?? this.ledger,
      contentCompatibility: contentCompatibility ?? this.contentCompatibility,
    ).withChecksum();
  }

  PlayerSave withChecksum() {
    return PlayerSave(
      schemaVersion: schemaVersion,
      playerId: playerId,
      createdAt: createdAt,
      lastSeenAt: lastSeenAt,
      progress: progress,
      wallet: wallet,
      boosters: boosters,
      settings: settings,
      purchases: purchases,
      collections: collections,
      events: events,
      renovationState: renovationState,
      ledger: ledger,
      contentCompatibility: contentCompatibility,
      checksum: _calculateChecksum(toJson(includeChecksum: false)),
    );
  }

  Map<String, Object?> toJson({bool includeChecksum = true}) {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'playerId': playerId,
      'createdAt': createdAt.toIso8601String(),
      'lastSeenAt': lastSeenAt.toIso8601String(),
      'progress': progress.toJson(),
      'wallet': wallet.toJson(),
      'boosters': <String, int>{
        for (final MapEntry<BoosterKind, int> entry in boosters.entries)
          entry.key.name: entry.value,
      },
      'settings': settings.toJson(),
      'purchases': purchases.toJson(),
      'collections': collections,
      'events': events,
      'renovationState': renovationState,
      'ledger': ledger,
      'contentCompatibility': contentCompatibility.toJson(),
      if (includeChecksum) 'checksum': checksum,
    };
  }

  static Map<BoosterKind, int> _initialBoosters() {
    return <BoosterKind, int>{
      BoosterKind.hint: 3,
      BoosterKind.shuffle: 1,
      BoosterKind.hammer: 1,
      BoosterKind.freezeTime: 0,
      BoosterKind.extraShelf: 0,
      BoosterKind.revealHidden: 0,
      BoosterKind.slowConveyor: 0,
    };
  }

  static Map<BoosterKind, int> _boostersFromJson(
    Map<String, Object?> boostersJson,
  ) {
    return <BoosterKind, int>{
      for (final MapEntry<String, Object?> entry in boostersJson.entries)
        BoosterKind.values.byName(entry.key): entry.value! as int,
    };
  }

  static String _calculateChecksum(Map<String, Object?> json) {
    final String encoded = jsonEncode(json);
    var hash = 17;
    for (final int unit in encoded.codeUnits) {
      hash = 37 * hash + unit;
    }
    return hash.toUnsigned(32).toRadixString(16);
  }
}

abstract interface class SaveRepository {
  Future<PlayerSave?> load();

  Future<void> save(PlayerSave save);
}
