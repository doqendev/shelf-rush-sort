enum AudioCue {
  productSelect,
  productSnap,
  invalidMove,
  tripleClear,
  hiddenReveal,
  laneGrab,
  laneMissWarning,
  boosterUse,
  timerWarning,
  win,
  loss,
  rewardDrawer,
}

abstract interface class AudioService {
  Future<void> play(AudioCue cue);
}

final class SilentAudioService implements AudioService {
  const SilentAudioService();

  @override
  Future<void> play(AudioCue cue) async {}
}
