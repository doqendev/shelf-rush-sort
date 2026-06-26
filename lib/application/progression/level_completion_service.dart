import '../../domain/content/level_def.dart';
import '../../domain/game/star_score.dart';
import '../../infrastructure/save/save_repository.dart';
import '../economy/economy_service.dart';
import '../game_session/game_session_state.dart';
import 'progression_service.dart';
import 'reward_service.dart';

/// The outcome of committing a level win — the updated save plus exactly what
/// was granted, so the win panel can show the truth instead of a recomputed
/// theoretical reward (third-pass audit P0.2).
final class LevelCompletionResult {
  const LevelCompletionResult({
    required this.save,
    required this.coinsGranted,
    required this.starsEarned,
    required this.firstCompletion,
  });

  final PlayerSave save;
  final int coinsGranted;
  final int starsEarned;
  final bool firstCompletion;
}

final class LevelCompletionService {
  const LevelCompletionService({
    this.progression = const ProgressionService(),
    this.rewards = const RewardService(),
    this.economy = const EconomyService(),
  });

  final ProgressionService progression;
  final RewardService rewards;
  final EconomyService economy;

  LevelCompletionResult commitWin({
    required PlayerSave save,
    required LevelDef level,
    required GameSessionState session,
    required RewardGrant reward,
  }) {
    final String ledgerKey = 'level_win:${level.id}:${session.attemptId}';
    final bool firstCompletion = level.levelNumber > save.highestLevelCompleted;
    final int earnedStars = starsForLevel(
      moveCount: session.moveCount,
      level: level,
    );
    final PlayerSave progressed = progression.onLevelWon(save, level);
    final PlayerSave updated = progressed.copyWith(
      lastSeenAt: DateTime.now().toUtc(),
      progress: _withStars(progressed.progress, level.id, earnedStars),
      collections: _recordDiscoveries(
        _recordSupportAttempt(save.collections, session),
        level,
        session,
      ),
    );
    if (!firstCompletion || updated.ledger.containsKey(ledgerKey)) {
      // Replay (or already-credited) win: stars/collection still update, but no
      // coins are granted — so the panel must not promise any (P0.2).
      return LevelCompletionResult(
        save: updated,
        coinsGranted: 0,
        starsEarned: earnedStars,
        firstCompletion: firstCompletion,
      );
    }
    final PlayerSave granted = economy.grantCoinsToSave(
      updated,
      reward.coins,
      reward.reason,
      sourceId: ledgerKey,
    );
    return LevelCompletionResult(
      save: granted,
      coinsGranted: granted.coins - updated.coins,
      starsEarned: earnedStars,
      firstCompletion: firstCompletion,
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

  /// Keeps the best star rating earned for [levelId] and the running total in
  /// sync, so the map can show per-level stars (second-pass audit M6 / 16).
  SaveProgress _withStars(SaveProgress progress, String levelId, int earned) {
    final int best = progress.levelStars[levelId] ?? 0;
    if (earned <= best) {
      return progress;
    }
    final Map<String, int> levelStars = Map<String, int>.of(progress.levelStars)
      ..[levelId] = earned;
    final int total = levelStars.values.fold<int>(0, (int a, int b) => a + b);
    return progress.copyWith(levelStars: levelStars, stars: total);
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
    GameSessionState session,
  ) {
    final Set<String> discovered = <String>{
      ...?(collections['discovered'] as List<Object?>?)?.cast<String>(),
    };
    // Only products the player actually saw on a shelf: the level's front cells
    // plus whatever was still visible at the end (e.g. a revealed hidden
    // product). NOT the hidden stack / lane queue / objective targets, which
    // they may never have uncovered (third-pass audit P1.6).
    for (final CompartmentDef compartment in level.compartments) {
      for (final String? sku in compartment.cells) {
        if (sku != null) {
          discovered.add(sku);
        }
      }
    }
    for (final product in session.board.visibleProducts) {
      discovered.add(product.skuId);
    }
    final List<String> sorted = discovered.toList()..sort();
    return <String, Object?>{...collections, 'discovered': sorted};
  }
}
