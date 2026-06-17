import 'save_repository.dart';

final class CloudSaveUnavailableException implements Exception {
  const CloudSaveUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'CloudSaveUnavailableException: $message';
}

final class CloudSaveRepository implements SaveRepository {
  const CloudSaveRepository({this.configured = false});

  final bool configured;

  @override
  Future<PlayerSave?> load() async {
    _throwIfUnavailable();
    return null;
  }

  @override
  Future<void> save(PlayerSave save) async {
    _throwIfUnavailable();
  }

  void _throwIfUnavailable() {
    if (!configured) {
      throw const CloudSaveUnavailableException(
        'Cloud save backend is not configured for this build.',
      );
    }
  }
}
