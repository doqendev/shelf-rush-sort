import 'purchase_service.dart';

abstract interface class PurchaseValidator {
  Future<bool> validate(PurchaseResult result);
}

final class LocalSandboxPurchaseValidator implements PurchaseValidator {
  const LocalSandboxPurchaseValidator();

  @override
  Future<bool> validate(PurchaseResult result) async => result.success;
}
