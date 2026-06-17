import '../boosters/booster_def.dart';

final class EconomyDef {
  EconomyDef({
    required this.startingCoins,
    required Map<BoosterKind, int> boosterPrices,
  }) : boosterPrices = Map<BoosterKind, int>.unmodifiable(boosterPrices);

  factory EconomyDef.fromJson(Map<String, Object?> json) {
    final Map<String, Object?> prices =
        json['boosterPrices']! as Map<String, Object?>;
    return EconomyDef(
      startingCoins: json['startingCoins']! as int,
      boosterPrices: <BoosterKind, int>{
        for (final MapEntry<String, Object?> entry in prices.entries)
          BoosterKind.values.byName(entry.key): entry.value! as int,
      },
    );
  }

  final int startingCoins;
  final Map<BoosterKind, int> boosterPrices;
}
