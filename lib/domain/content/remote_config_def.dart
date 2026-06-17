final class RemoteConfigDef {
  RemoteConfigDef({
    required this.firstInterstitialLevel,
    required this.adCooldownSeconds,
    required this.laneSpeedMultiplier,
    this.timerMultiplier = 1,
    this.boosterOfferThreshold = 2,
    this.hardLevelFrequency = 5,
    this.tutorialAssistanceLevel = 5,
    List<String> failRescuePriority = const <String>[],
    required Map<String, bool> featureFlags,
  }) : failRescuePriority = List<String>.unmodifiable(failRescuePriority),
       featureFlags = Map<String, bool>.unmodifiable(featureFlags);

  factory RemoteConfigDef.fromJson(Map<String, Object?> json) {
    final Map<String, Object?> flags =
        json['featureFlags']! as Map<String, Object?>;
    return RemoteConfigDef(
      firstInterstitialLevel: json['firstInterstitialLevel']! as int,
      adCooldownSeconds: json['adCooldownSeconds']! as int,
      laneSpeedMultiplier: (json['laneSpeedMultiplier']! as num).toDouble(),
      timerMultiplier: (json['timerMultiplier'] as num? ?? 1).toDouble(),
      boosterOfferThreshold: json['boosterOfferThreshold'] as int? ?? 2,
      hardLevelFrequency: json['hardLevelFrequency'] as int? ?? 5,
      tutorialAssistanceLevel: json['tutorialAssistanceLevel'] as int? ?? 5,
      failRescuePriority:
          (json['failRescuePriority'] as List<Object?>? ?? const <Object?>[])
              .cast<String>(),
      featureFlags: <String, bool>{
        for (final MapEntry<String, Object?> entry in flags.entries)
          entry.key: entry.value! as bool,
      },
    );
  }

  final int firstInterstitialLevel;
  final int adCooldownSeconds;
  final double laneSpeedMultiplier;
  final double timerMultiplier;
  final int boosterOfferThreshold;
  final int hardLevelFrequency;
  final int tutorialAssistanceLevel;
  final List<String> failRescuePriority;
  final Map<String, bool> featureFlags;
}
