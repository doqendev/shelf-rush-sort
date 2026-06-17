import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/application/economy/economy_service.dart';
import 'package:shelf_rush_sort/infrastructure/save/save_repository.dart';

void main() {
  test('grantCoinsToSave records a ledger entry and updates balance', () {
    final PlayerSave save = PlayerSave.newPlayer(
      playerId: 'anon_test',
      startingCoins: 500,
    );

    final PlayerSave updated = const EconomyService().grantCoinsToSave(
      save,
      100,
      'test_reward',
      sourceId: 'txn_test',
    );

    expect(updated.coins, 600);
    expect(updated.ledger, contains('txn_test'));
    expect(updated.hasValidChecksum, isTrue);
  });
}
