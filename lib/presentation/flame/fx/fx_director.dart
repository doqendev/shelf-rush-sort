import '../../../application/game_session/game_session_state.dart';
import '../../../infrastructure/platform/audio_service.dart';
import '../../../infrastructure/platform/haptics_service.dart';
import '../shelf_world.dart';

final class FxDirector {
  const FxDirector();

  Future<void> handleEvents(
    List<SessionEvent> events, {
    required ShelfWorld world,
    required AudioService audio,
    required HapticsService haptics,
    required bool reduceMotion,
  }) async {
    for (final SessionEvent event in events) {
      final _CueMap? cue = _cueFor(event);
      if (cue == null) {
        continue;
      }
      await audio.play(cue.audio);
      await haptics.play(cue.haptic);
      if (!reduceMotion) {
        _scheduleVisualMarker(world, event);
      }
    }
  }

  _CueMap? _cueFor(SessionEvent event) {
    return switch (event.type) {
      SessionEventType.selectionChanged => const _CueMap(
        AudioCue.productSelect,
        HapticCue.select,
      ),
      SessionEventType.invalidMove => const _CueMap(
        AudioCue.invalidMove,
        HapticCue.invalid,
      ),
      SessionEventType.moveApplied => const _CueMap(
        AudioCue.productSnap,
        HapticCue.snap,
      ),
      SessionEventType.tripleCleared => const _CueMap(
        AudioCue.tripleClear,
        HapticCue.clear,
      ),
      SessionEventType.hiddenRevealed => const _CueMap(
        AudioCue.hiddenReveal,
        HapticCue.snap,
      ),
      SessionEventType.laneGrabbed => const _CueMap(
        AudioCue.laneGrab,
        HapticCue.select,
      ),
      SessionEventType.laneMissed => const _CueMap(
        AudioCue.laneMissWarning,
        HapticCue.invalid,
      ),
      SessionEventType.boosterUsed => const _CueMap(
        AudioCue.boosterUse,
        HapticCue.booster,
      ),
      SessionEventType.levelWon => const _CueMap(AudioCue.win, HapticCue.win),
      SessionEventType.levelFailed => const _CueMap(
        AudioCue.loss,
        HapticCue.loss,
      ),
      SessionEventType.revived || SessionEventType.rewardCommitted => null,
    };
  }

  void _scheduleVisualMarker(ShelfWorld world, SessionEvent event) {
    // Non-blocking: gameplay state never waits for presentation effects. The
    // retained world owns the component lifecycle and preserves FX across
    // board rebuilds until they self-remove.
    if (event.type == SessionEventType.tripleCleared) {
      final Object? compartment = event.payload['compartment'];
      final Object? sku = event.payload['sku_id'];
      if (compartment is int && sku is String) {
        final Object? combo = event.payload['combo'];
        world.playTripleClearFx(compartment, combo is int ? combo : 0, sku);
      }
    }
  }
}

final class _CueMap {
  const _CueMap(this.audio, this.haptic);

  final AudioCue audio;
  final HapticCue haptic;
}
