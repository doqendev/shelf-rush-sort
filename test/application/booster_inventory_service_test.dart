import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/application/boosters/booster_inventory_service.dart';
import 'package:shelf_rush_sort/domain/boosters/booster_def.dart';
import 'package:shelf_rush_sort/infrastructure/save/save_repository.dart';

void main() {
  const BoosterInventoryService service = BoosterInventoryService();
  final DateTime now = DateTime.utc(2026);

  PlayerSave freshSave() =>
      PlayerSave.newPlayer(playerId: 'p1', startingCoins: 500);

  test('canUse reflects owned inventory', () {
    final PlayerSave save = freshSave();
    expect(service.canUse(save, BoosterKind.hint), isTrue); // starts with 3
    expect(service.canUse(save, BoosterKind.freezeTime), isFalse); // starts 0
  });

  test('consume decrements an owned booster and no-ops when empty', () {
    final PlayerSave save = freshSave();

    final PlayerSave afterHint = service.consume(save, BoosterKind.hint);
    expect(service.countOf(afterHint, BoosterKind.hint), 2);

    final PlayerSave afterEmpty = service.consume(save, BoosterKind.freezeTime);
    expect(service.countOf(afterEmpty, BoosterKind.freezeTime), 0);
    expect(afterEmpty.coins, save.coins);
  });

  test('purchase adds inventory and deducts coins when affordable', () {
    final PlayerSave save = freshSave();
    final PlayerSave bought = service.purchase(
      save,
      BoosterKind.freezeTime,
      5,
      100,
      now: now,
    );
    expect(service.countOf(bought, BoosterKind.freezeTime), 5);
    expect(bought.coins, save.coins - 100);
  });

  test('purchase is rejected when the player cannot afford it', () {
    final PlayerSave save = freshSave();
    final PlayerSave attempted = service.purchase(
      save,
      BoosterKind.hint,
      1,
      100000,
      now: now,
    );
    expect(attempted.coins, save.coins);
    expect(service.countOf(attempted, BoosterKind.hint), 3);
  });
}
