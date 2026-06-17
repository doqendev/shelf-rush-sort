import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/infrastructure/save/save_migrations.dart';
import 'package:shelf_rush_sort/infrastructure/save/save_repository.dart';

void main() {
  test(
    'migration runner applies ordered migrations and refreshes checksum',
    () {
      final PlayerSave migrated = SaveMigrationRunner(
        migrations: const <SaveMigration>[
          _SchemaMigration(from: 1, to: 2, coinDelta: 25),
          _SchemaMigration(from: 2, to: 3, coinDelta: 50),
        ],
      ).migrate(_save(), 3);

      expect(migrated.schemaVersion, 3);
      expect(migrated.coins, 575);
      expect(migrated.hasValidChecksum, isTrue);
    },
  );

  test('migration runner rejects backwards targets', () {
    expect(
      () => const SaveMigrationRunner().migrate(
        _save().copyWith(schemaVersion: 2),
        1,
      ),
      throwsArgumentError,
    );
  });

  test('migration runner reports missing migration', () {
    expect(
      () => const SaveMigrationRunner().migrate(_save(), 2),
      throwsStateError,
    );
  });

  test('migration runner rejects migration that returns wrong version', () {
    expect(
      () => SaveMigrationRunner(
        migrations: const <SaveMigration>[
          _WrongVersionMigration(from: 1, to: 2),
        ],
      ).migrate(_save(), 2),
      throwsStateError,
    );
  });
}

PlayerSave _save() {
  return PlayerSave.newPlayer(playerId: 'anon_migration', startingCoins: 500);
}

final class _SchemaMigration implements SaveMigration {
  const _SchemaMigration({
    required this.from,
    required this.to,
    required this.coinDelta,
  });

  final int from;
  final int to;
  final int coinDelta;

  @override
  int get fromVersion => from;

  @override
  int get toVersion => to;

  @override
  PlayerSave migrate(PlayerSave oldSave) {
    return oldSave.copyWith(
      schemaVersion: to,
      coins: oldSave.coins + coinDelta,
    );
  }
}

final class _WrongVersionMigration implements SaveMigration {
  const _WrongVersionMigration({required this.from, required this.to});

  final int from;
  final int to;

  @override
  int get fromVersion => from;

  @override
  int get toVersion => to;

  @override
  PlayerSave migrate(PlayerSave oldSave) {
    return oldSave.copyWith(coins: oldSave.coins + 1);
  }
}
