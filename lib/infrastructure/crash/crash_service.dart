abstract interface class CrashService {
  Future<void> recordError(Object error, StackTrace stackTrace);
}

final class DebugCrashService implements CrashService {
  const DebugCrashService();

  @override
  Future<void> recordError(Object error, StackTrace stackTrace) async {}
}
