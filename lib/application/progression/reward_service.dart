final class RewardGrant {
  const RewardGrant({required this.coins, required this.reason});

  final int coins;
  final String reason;
}

final class RewardService {
  const RewardService();

  RewardGrant levelWinReward(int levelNumber) {
    return RewardGrant(coins: 50 + levelNumber * 2, reason: 'level_win');
  }
}
