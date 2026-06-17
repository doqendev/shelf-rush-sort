import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/application/liveops/daily_order_service.dart';
import 'package:shelf_rush_sort/infrastructure/save/save_repository.dart';

void main() {
  test('daily reward grants first-day coins and ledger marker', () {
    const DailyOrderService service = DailyOrderService();
    final PlayerSave save = PlayerSave.newPlayer(
      playerId: 'daily_test',
      startingCoins: 500,
    );
    final DateTime now = DateTime.utc(2026, 6, 17, 12);

    final PlayerSave claimed = service.claim(save, now);

    expect(claimed.coins, 550);
    expect(claimed.events['dailyReward'], isA<Map<String, Object?>>());
    expect(claimed.ledger, contains('daily_reward_2026-06-17'));
    expect(claimed.hasValidChecksum, isTrue);
  });

  test('daily reward cannot be claimed twice on the same day', () {
    const DailyOrderService service = DailyOrderService();
    final DateTime now = DateTime.utc(2026, 6, 17, 12);
    final PlayerSave save = service.claim(
      PlayerSave.newPlayer(playerId: 'daily_test', startingCoins: 500),
      now,
    );

    final PlayerSave secondClaim = service.claim(save, now);

    expect(secondClaim.coins, 550);
    expect(identical(secondClaim, save), isTrue);
    expect(service.evaluate(secondClaim, now).canClaim, isFalse);
  });

  test('daily reward increments consecutive streak and resets after a gap', () {
    const DailyOrderService service = DailyOrderService();
    final PlayerSave save = PlayerSave.newPlayer(
      playerId: 'daily_test',
      startingCoins: 500,
    );

    final PlayerSave dayOne = service.claim(save, DateTime.utc(2026, 6, 17));
    final DailyRewardState dayTwo = service.evaluate(
      dayOne,
      DateTime.utc(2026, 6, 18),
    );
    final DailyRewardState afterGap = service.evaluate(
      dayOne,
      DateTime.utc(2026, 6, 20),
    );

    expect(dayTwo.streakDay, 2);
    expect(dayTwo.rewardCoins, 60);
    expect(afterGap.streakDay, 1);
    expect(afterGap.rewardCoins, 50);
  });
}
