import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/domain/boosters/booster_def.dart';
import 'package:shelf_rush_sort/infrastructure/save/save_repository.dart';

void main() {
  test('new player save serializes in source-of-truth nested shape', () {
    final PlayerSave save = PlayerSave.newPlayer(
      playerId: 'anon_test',
      startingCoins: 500,
    );
    final Map<String, Object?> json = save.toJson();

    expect(json['progress'], isA<Map<String, Object?>>());
    expect(json['wallet'], isA<Map<String, Object?>>());
    expect(json['settings'], isA<Map<String, Object?>>());
    expect(json['purchases'], isA<Map<String, Object?>>());
    expect(json['collections'], isA<Map<String, Object?>>());
    expect(json['events'], isA<Map<String, Object?>>());
    expect(json['renovationState'], isA<Map<String, Object?>>());
    expect(json['ledger'], isA<Map<String, Object?>>());
    expect(json['contentCompatibility'], isA<Map<String, Object?>>());
    expect(save.hasValidChecksum, isTrue);
  });

  test(
    'copyWith updates convenience fields while preserving nested structure',
    () {
      final PlayerSave save =
          PlayerSave.newPlayer(
            playerId: 'anon_test',
            startingCoins: 500,
          ).copyWith(
            highestLevelCompleted: 7,
            coins: 725,
            music: false,
            reduceMotion: true,
            removeAds: true,
            consentState: 'granted',
          );

      expect(save.progress.highestLevelCompleted, 7);
      expect(save.wallet.coins, 725);
      expect(save.settings.music, isFalse);
      expect(save.settings.reduceMotion, isTrue);
      expect(save.settings.consentState, 'granted');
      expect(save.purchases.removeAds, isTrue);
      expect(save.hasValidChecksum, isTrue);
    },
  );

  test('legacy flat save migrates to nested save shape', () {
    final PlayerSave legacy = PlayerSave.fromJson(<String, Object?>{
      'schemaVersion': 1,
      'playerId': 'anon_legacy',
      'createdAt': '2026-06-17T00:00:00Z',
      'lastSeenAt': '2026-06-17T00:00:00Z',
      'highestLevelCompleted': 3,
      'coins': 640,
      'boosters': <String, int>{
        for (final BoosterKind booster in BoosterKind.values) booster.name: 0,
      },
      'music': false,
      'sfx': true,
      'haptics': false,
      'reduceMotion': true,
      'removeAds': false,
      'checksum': 'legacy',
    });

    expect(legacy.highestLevelCompleted, 3);
    expect(legacy.wallet.coins, 640);
    expect(legacy.settings.inputMode, 'hybrid');
    expect(
      legacy.toJson(),
      containsPair('progress', isA<Map<String, Object?>>()),
    );
    expect(legacy.hasValidChecksum, isTrue);
  });
}
