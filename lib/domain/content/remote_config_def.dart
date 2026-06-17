final class RemoteConfigDef {
  RemoteConfigDef({
    required this.firstInterstitialLevel,
    required this.adCooldownSeconds,
    required this.laneSpeedMultiplier,
    required Map<String, bool> featureFlags,
  }) : featureFlags = Map<String, bool>.unmodifiable(featureFlags);

  factory RemoteConfigDef.fromJson(Map<String, Object?> json) {
    final Map<String, Object?> flags =
        json['featureFlags']! as Map<String, Object?>;
    return RemoteConfigDef(
      firstInterstitialLevel: json['firstInterstitialLevel']! as int,
      adCooldownSeconds: json['adCooldownSeconds']! as int,
      laneSpeedMultiplier: (json['laneSpeedMultiplier']! as num).toDouble(),
      featureFlags: <String, bool>{
        for (final MapEntry<String, Object?> entry in flags.entries)
          entry.key: entry.value! as bool,
      },
    );
  }

  final int firstInterstitialLevel;
  final int adCooldownSeconds;
  final double laneSpeedMultiplier;
  final Map<String, bool> featureFlags;
}
