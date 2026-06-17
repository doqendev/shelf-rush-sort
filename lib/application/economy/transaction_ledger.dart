enum EconomyTransactionType { grant, spend }

final class EconomyTransaction {
  const EconomyTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final EconomyTransactionType type;
  final int amount;
  final String reason;
  final DateTime createdAt;
}

final class TransactionLedger {
  TransactionLedger({
    List<EconomyTransaction> transactions = const <EconomyTransaction>[],
  }) : transactions = List<EconomyTransaction>.unmodifiable(transactions);

  final List<EconomyTransaction> transactions;

  TransactionLedger append(EconomyTransaction transaction) {
    return TransactionLedger(
      transactions: <EconomyTransaction>[...transactions, transaction],
    );
  }
}
