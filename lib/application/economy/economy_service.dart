import '../../domain/boosters/booster_def.dart';
import '../../infrastructure/save/save_repository.dart';
import 'transaction_ledger.dart';

final class WalletState {
  WalletState({
    required this.coins,
    required Map<BoosterKind, int> boosters,
    TransactionLedger? ledger,
  }) : boosters = Map<BoosterKind, int>.unmodifiable(boosters),
       ledger = ledger ?? TransactionLedger();

  final int coins;
  final Map<BoosterKind, int> boosters;
  final TransactionLedger ledger;

  WalletState copyWith({
    int? coins,
    Map<BoosterKind, int>? boosters,
    TransactionLedger? ledger,
  }) {
    return WalletState(
      coins: coins ?? this.coins,
      boosters: boosters ?? this.boosters,
      ledger: ledger ?? this.ledger,
    );
  }
}

final class EconomyService {
  const EconomyService();

  PlayerSave grantCoinsToSave(
    PlayerSave save,
    int amount,
    String reason, {
    String? sourceId,
  }) {
    final String id = sourceId ?? 'grant_${save.ledger.length}';
    final Map<String, Object?> ledger = Map<String, Object?>.of(save.ledger);
    ledger[id] = <String, Object?>{
      'type': EconomyTransactionType.grant.name,
      'amount': amount,
      'reason': reason,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    return save.copyWith(coins: save.coins + amount, ledger: ledger);
  }

  WalletState grantCoins(WalletState wallet, int amount, String reason) {
    return wallet.copyWith(
      coins: wallet.coins + amount,
      ledger: wallet.ledger.append(
        EconomyTransaction(
          id: 'grant_${wallet.ledger.transactions.length}',
          type: EconomyTransactionType.grant,
          amount: amount,
          reason: reason,
          createdAt: DateTime.now().toUtc(),
        ),
      ),
    );
  }

  WalletState spendCoins(WalletState wallet, int amount, String reason) {
    if (wallet.coins < amount) {
      return wallet;
    }
    return wallet.copyWith(
      coins: wallet.coins - amount,
      ledger: wallet.ledger.append(
        EconomyTransaction(
          id: 'spend_${wallet.ledger.transactions.length}',
          type: EconomyTransactionType.spend,
          amount: amount,
          reason: reason,
          createdAt: DateTime.now().toUtc(),
        ),
      ),
    );
  }
}
