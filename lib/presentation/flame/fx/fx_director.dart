import '../../../application/game_session/game_session_state.dart';

final class FxDirector {
  const FxDirector();

  void handleEvents(List<SessionEvent> events) {
    // Visual effects are deliberately event-driven from domain/application output.
  }
}
