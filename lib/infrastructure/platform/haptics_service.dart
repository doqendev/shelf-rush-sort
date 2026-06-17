import 'package:flutter/services.dart';

enum HapticCue { select, snap, invalid, clear, combo, booster, win, loss }

abstract interface class HapticsService {
  Future<void> play(HapticCue cue);
}

final class FlutterHapticsService implements HapticsService {
  const FlutterHapticsService({required this.enabled});

  final bool enabled;

  @override
  Future<void> play(HapticCue cue) async {
    if (!enabled) {
      return;
    }
    switch (cue) {
      case HapticCue.select:
      case HapticCue.snap:
        await HapticFeedback.lightImpact();
      case HapticCue.invalid:
        await HapticFeedback.mediumImpact();
      case HapticCue.clear:
      case HapticCue.combo:
      case HapticCue.booster:
      case HapticCue.win:
        await HapticFeedback.heavyImpact();
      case HapticCue.loss:
        await HapticFeedback.vibrate();
    }
  }
}
