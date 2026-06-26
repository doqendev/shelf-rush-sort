import '../../domain/content/level_def.dart';
import '../../infrastructure/save/save_repository.dart';
import '../economy/economy_service.dart';
import '../game_session/game_session_state.dart';
import 'progression_service.dart';
import 'reward_service.dart';

final class LevelCompletionService {
  const LevelCompletionService({
    this.progression = const ProgressionService(),
    this.rewards = const RewardService(),
    this.economy = const EconomyService(),
  });

  final ProgressionService progression;
  final RewardService rewards;
  final EconomyService economy;

  PlayerSave commitWin({
    required PlayerSave save,
    required LevelDef level,
    required GameSessionState session,
    required RewardGrant reward,
  }) {
    final String ledgerKey = 'level_win:${level.id}:${session.attemptId}';
    final bool firstCompletion = level.levelNumber > save.highestLevelCompleted;
    final PlayerSave updated = progression
        .onLevelWon(save, level)
        .copyWith(
          lastSeenAt: DateTime.now().toUtc(),
          collections: _recordDiscoveries(
            _recordSupportAttempt(save.collections, session),
            level,
          ),
        );
    if (!firstCompletion || updated.ledger.containsKey(ledgerKey)) {
      return updated;
    }
    return economy.grantCoinsToSave(
      updated,
      reward.coins,
      reward.reason,
      sourceId: ledgerKey,
    );
  }

  PlayerSave commitDoubleReward({
    required PlayerSave save,
    required LevelDef level,
    required RewardGrant reward,
    required String adTransactionId,
  }) {
    final String ledgerKey = 'level_double:${level.id}:$adTransactionId';
    return economy.grantCoinsToSave(
      save,
      reward.coins,
      'level_win_double_reward',
      sourceId: ledgerKey,
    );
  }

  Map<String, Object?> _recordSupportAttempt(
    Map<String, Object?> collections,
    GameSessionState session,
  ) {
    final Map<String, Object?> updated = Map<String, Object?>.of(collections);
    final List<Object?> attempts = List<Object?>.of(
      updated['recentAttempts'] as List<Object?>? ?? const <Object?>[],
    );
    attempts.insert(0, <String, Object?>{
      'attemptId': session.attemptId,
      'levelId': session.level.id,
      'levelNumber': session.level.levelNumber,
      'status': session.status.name,
      'moves': session.moveCount,
      'failReason': session.failReason.name,
      'finalStateHash': session.board.stableHash,
      'replay': session.replay.toJson(),
    });
    updated['recentAttempts'] = attempts.take(5).toList(growable: false);
    return updated;
  }

  /// Records every product the [level] contains as "discovered" so the
  /// Collection screen reflects real progress instead of always-locked tiles
  /// (second-pass audit M6 / P1.8).
  Map<String, Object?> _recordDiscoveries(
    Map<String, Object?> collections,
    LevelDef level,
  ) {
    final Set<String> discovered = <String>{
      ...?(collections['discovered'] as List<Object?>?)?.cast<String>(),
    };
    for (final CompartmentDef compartment in level.compartments) {
      for (final String? sku in compartment.cells) {
        if (sku != null) {
          discovered.add(sku);
        }
      }
      discovered.addAll(compartment.hidden);
    }
    for (final lane in level.movingLanes) {
      for (final product in lane.queue) {
        discovered.add(product.skuId);
      }
    }
    discovered.addAll(level.objective.targetCounts.keys);
    final List<String> sorted = discovered.toList()..sort();
    return <String, Object?>{...collections, 'discovered': sorted};
  }
}
