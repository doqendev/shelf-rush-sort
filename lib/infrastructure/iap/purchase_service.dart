enum PurchaseProduct { removeAds, starterPack, coinPackSmall, coinPackLarge }

final class PurchaseResult {
  const PurchaseResult({
    required this.success,
    this.transactionId,
    this.errorCode,
  });

  final bool success;
  final String? transactionId;
  final String? errorCode;
}

abstract interface class PurchaseService {
  Future<PurchaseResult> purchase(PurchaseProduct product);

  Future<void> restorePurchases();
}

final class FakePurchaseService implements PurchaseService {
  const FakePurchaseService();

  @override
  Future<PurchaseResult> purchase(PurchaseProduct product) async {
    return PurchaseResult(success: true, transactionId: 'fake_${product.name}');
  }

  @override
  Future<void> restorePurchases() async {}
}

final class StorePurchaseService implements PurchaseService {
  const StorePurchaseService();

  @override
  Future<PurchaseResult> purchase(PurchaseProduct product) async {
    return const PurchaseResult(success: false, errorCode: 'not_configured');
  }

  @override
  Future<void> restorePurchases() async {}
}
