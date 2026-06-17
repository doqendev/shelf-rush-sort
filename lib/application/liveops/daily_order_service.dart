import '../../infrastructure/save/save_repository.dart';

final class DailyRewardState {
  const DailyRewardState({
    required this.todayKey,
    required this.streakDay,
    required this.rewardCoins,
    required this.canClaim,
  });

  final String todayKey;
  final int streakDay;
  final int rewardCoins;
  final bool canClaim;
}

final class DailyOrderService {
  const DailyOrderService();

  DailyRewardState evaluate(PlayerSave save, DateTime nowUtc) {
    final DateTime normalized = nowUtc.toUtc();
    final String todayKey = _dateKey(normalized);
    final Map<String, Object?> record = _dailyRecord(save);
    final String? lastClaimedDate = record['lastClaimedDate'] as String?;
    final int previousStreak = record['streakDay'] as int? ?? 0;
    if (lastClaimedDate == todayKey) {
      return DailyRewardState(
        todayKey: todayKey,
        streakDay: previousStreak.clamp(1, 365),
        rewardCoins: _rewardForStreak(previousStreak.clamp(1, 365)),
        canClaim: false,
      );
    }
    final bool consecutive =
        lastClaimedDate ==
        _dateKey(normalized.subtract(const Duration(days: 1)));
    final int streakDay = consecutive ? previousStreak + 1 : 1;
    return DailyRewardState(
      todayKey: todayKey,
      streakDay: streakDay,
      rewardCoins: _rewardForStreak(streakDay),
      canClaim: true,
    );
  }

  PlayerSave claim(PlayerSave save, DateTime nowUtc) {
    final DailyRewardState state = evaluate(save, nowUtc);
    if (!state.canClaim) {
      return save;
    }
    final Map<String, Object?> events = Map<String, Object?>.of(save.events)
      ..['dailyReward'] = <String, Object?>{
        'lastClaimedDate': state.todayKey,
        'streakDay': state.streakDay,
      };
    final Map<String, Object?> ledger = Map<String, Object?>.of(save.ledger)
      ..['daily_reward_${state.todayKey}'] = <String, Object?>{
        'type': 'grant',
        'currency': 'coins',
        'amount': state.rewardCoins,
        'reason': 'daily_reward',
      };
    return save.copyWith(
      coins: save.coins + state.rewardCoins,
      events: events,
      ledger: ledger,
    );
  }

  Map<String, Object?> _dailyRecord(PlayerSave save) {
    return save.events['dailyReward'] as Map<String, Object?>? ??
        const <String, Object?>{};
  }

  int _rewardForStreak(int streakDay) {
    return 50 + ((streakDay - 1).clamp(0, 6) * 10);
  }

  String _dateKey(DateTime date) {
    final DateTime utc = date.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}';
  }
}
