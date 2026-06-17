import 'save_repository.dart';

abstract interface class SaveMigration {
  int get fromVersion;
  int get toVersion;

  PlayerSave migrate(PlayerSave oldSave);
}

final class SaveMigrationRunner {
  const SaveMigrationRunner({this.migrations = const <SaveMigration>[]});

  final List<SaveMigration> migrations;

  PlayerSave migrate(PlayerSave save, int targetVersion) {
    if (targetVersion < save.schemaVersion) {
      throw ArgumentError.value(
        targetVersion,
        'targetVersion',
        'Cannot migrate save backwards from v${save.schemaVersion}.',
      );
    }
    var current = save;
    while (current.schemaVersion < targetVersion) {
      final SaveMigration migration = migrations.firstWhere(
        (SaveMigration item) => item.fromVersion == current.schemaVersion,
        orElse: () {
          throw StateError(
            'No save migration registered from v${current.schemaVersion}.',
          );
        },
      );
      if (migration.toVersion <= current.schemaVersion) {
        throw StateError(
          'Save migration from v${migration.fromVersion} must advance version.',
        );
      }
      if (migration.toVersion > targetVersion) {
        throw StateError(
          'Save migration from v${migration.fromVersion} overshoots '
          'target v$targetVersion.',
        );
      }
      final PlayerSave migrated = migration.migrate(current).withChecksum();
      if (migrated.schemaVersion != migration.toVersion) {
        throw StateError(
          'Save migration from v${migration.fromVersion} returned '
          'v${migrated.schemaVersion}, expected v${migration.toVersion}.',
        );
      }
      current = migrated;
    }
    return current;
  }
}
