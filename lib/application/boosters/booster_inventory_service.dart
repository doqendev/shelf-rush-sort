import '../../domain/boosters/booster_def.dart';
import '../../infrastructure/save/save_repository.dart';
import '../economy/transaction_ledger.dart';

/// Owns the booster economy against the player's saved inventory
/// (`PlayerSave.boosters`): how many a player owns, whether a booster can be
/// used, consuming one on use, and buying more. Replaces the previous flow
/// where the dock fired boosters without checking or decrementing anything
/// (second-pass audit M4 / P0.4).
final class BoosterInventoryService {
  const BoosterInventoryService();

  int countOf(PlayerSave save, BoosterKind kind) => save.boosters[kind] ?? 0;

  /// A booster can be used only if at least one is owned.
  bool canUse(PlayerSave save, BoosterKind kind) => countOf(save, kind) > 0;

  /// Decrements one [kind] when available; returns the save unchanged
  /// otherwise (so callers can branch to an upsell).
  PlayerSave consume(PlayerSave save, BoosterKind kind) {
    final int count = countOf(save, kind);
    if (count <= 0) {
      return save;
    }
    final Map<BoosterKind, int> next = Map<BoosterKind, int>.of(save.boosters);
    next[kind] = count - 1;
    return save.copyWith(boosters: next);
  }

  /// Buys [quantity] of [kind] for [price] coins when affordable, recording a
  /// ledger entry; returns the save unchanged when unaffordable.
  PlayerSave purchase(
    PlayerSave save,
    BoosterKind kind,
    int quantity,
    int price, {
    DateTime? now,
  }) {
    if (price > 0 && save.coins < price) {
      return save;
    }
    final Map<BoosterKind, int> nextBoosters = Map<BoosterKind, int>.of(
      save.boosters,
    );
    nextBoosters[kind] = countOf(save, kind) + quantity;
    final Map<String, Object?> ledger = Map<String, Object?>.of(save.ledger);
    final String id = 'buy_${kind.name}_${ledger.length}';
    ledger[id] = <String, Object?>{
      'type': EconomyTransactionType.spend.name,
      'amount': price,
      'reason': 'buy_booster_${kind.name}',
      'createdAt': (now ?? DateTime.now().toUtc()).toIso8601String(),
    };
    return save.copyWith(
      coins: save.coins - price,
      boosters: nextBoosters,
      ledger: ledger,
    );
  }
}
