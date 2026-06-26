import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/application/game_session/game_session_state.dart';
import 'package:shelf_rush_sort/application/progression/level_completion_service.dart';
import 'package:shelf_rush_sort/application/progression/reward_service.dart';
import 'package:shelf_rush_sort/domain/content/level_def.dart';
import 'package:shelf_rush_sort/domain/game/board_rules.dart';
import 'package:shelf_rush_sort/domain/game/objective.dart';
import 'package:shelf_rush_sort/domain/game/replay.dart';
import 'package:shelf_rush_sort/domain/game/timer.dart';
import 'package:shelf_rush_sort/domain/moving_lanes/moving_lane_state.dart';
import 'package:shelf_rush_sort/infrastructure/save/save_repository.dart';

void main() {
  test('commitWin grants base reward once and completes progress', () {
    final LevelDef level = _level();
    final session = _wonSession(level, attemptId: 'attempt_1');
    final PlayerSave save = PlayerSave.newPlayer(
      playerId: 'player',
      startingCoins: 0,
    );
    const LevelCompletionService service = LevelCompletionService();
    const RewardGrant reward = RewardGrant(coins: 52, reason: 'level_win');

    final LevelCompletionResult first = service.commitWin(
      save: save,
      level: level,
      session: session,
      reward: reward,
    );
    final LevelCompletionResult second = service.commitWin(
      save: first.save,
      level: level,
      session: session,
      reward: reward,
    );

    expect(first.save.highestLevelCompleted, 1);
    // First completion grants coins; the replay grants none — the win panel
    // must reflect this, not a recomputed reward (third-pass audit P0.2).
    expect(first.coinsGranted, 52);
    expect(first.save.coins, 52);
    expect(second.coinsGranted, 0);
    expect(second.save.coins, 52);
    expect(second.save.ledger, hasLength(first.save.ledger.length));
  });

  test('commitDoubleReward grants only the additional delta once', () {
    final LevelDef level = _level();
    final PlayerSave save = PlayerSave.newPlayer(
      playerId: 'player',
      startingCoins: 52,
    );
    const LevelCompletionService service = LevelCompletionService();
    const RewardGrant reward = RewardGrant(coins: 52, reason: 'level_win');

    final PlayerSave first = service.commitDoubleReward(
      save: save,
      level: level,
      reward: reward,
      adTransactionId: 'ad_1',
    );
    final PlayerSave second = service.commitDoubleReward(
      save: first,
      level: level,
      reward: reward,
      adTransactionId: 'ad_1',
    );

    expect(first.coins, 104);
    expect(second.coins, 104);
  });

  test('commitWin records the level products as discovered (M6 / P1.8)', () {
    final LevelDef level = _levelWithProducts();
    final session = _wonSession(level, attemptId: 'attempt_disc');
    final PlayerSave save = PlayerSave.newPlayer(
      playerId: 'player',
      startingCoins: 0,
    );
    const LevelCompletionService service = LevelCompletionService();
    const RewardGrant reward = RewardGrant(coins: 10, reason: 'level_win');

    final LevelCompletionResult updated = service.commitWin(
      save: save,
      level: level,
      session: session,
      reward: reward,
    );

    final List<Object?> discovered =
        updated.save.collections['discovered']! as List<Object?>;
    expect(
      discovered.cast<String>(),
      containsAll(<String>['sku_000', 'sku_001', 'sku_002']),
    );
    // The hidden product was never revealed, so it must NOT be unlocked: only
    // products actually seen on a shelf count (third-pass audit P1.6).
    expect(discovered.cast<String>(), isNot(contains('sku_050')));
  });

  test('commitWin persists per-level stars and the running total (M6)', () {
    final LevelDef level = _levelWithProducts();
    final session = _wonSession(level, attemptId: 'attempt_stars');
    final PlayerSave save = PlayerSave.newPlayer(
      playerId: 'player',
      startingCoins: 0,
    );
    const LevelCompletionService service = LevelCompletionService();
    const RewardGrant reward = RewardGrant(coins: 10, reason: 'level_win');

    final LevelCompletionResult updated = service.commitWin(
      save: save,
      level: level,
      session: session,
      reward: reward,
    );

    final int? levelStars = updated.save.progress.levelStars[level.id];
    expect(levelStars, isNotNull);
    expect(levelStars, greaterThan(0));
    // Only one level completed, so the total equals that level's rating.
    expect(updated.save.progress.stars, levelStars);
  });
}

GameSessionState _wonSession(LevelDef level, {required String attemptId}) {
  final board = const BoardRules().resolveBoard(level.createBoardState()).state;
  return GameSessionState(
    level: level,
    board: board,
    objective: const ObjectiveRules().initialState(
      requirement: level.objective,
      board: board,
    ),
    timer: LevelTimer.fromSeconds(null),
    replay: ReplayLog(levelId: level.id, seed: level.seed),
    lanes: const <MovingLaneState>[],
    attemptId: attemptId,
    status: GameSessionStatus.won,
  );
}

LevelDef _level() {
  return LevelDef(
    id: 'level_0001',
    levelNumber: 1,
    title: 'Level 1',
    seed: 1,
    objective: ObjectiveRequirement(type: ObjectiveType.clearAll),
    compartments: <CompartmentDef>[
      for (var index = 0; index < 15; index += 1)
        CompartmentDef(index: index, cells: const <String?>[null, null, null]),
    ],
  );
}

LevelDef _levelWithProducts() {
  return LevelDef(
    id: 'level_disc',
    levelNumber: 2,
    title: 'Discovery',
    seed: 2,
    objective: ObjectiveRequirement(type: ObjectiveType.clearAll),
    compartments: <CompartmentDef>[
      CompartmentDef(
        index: 0,
        cells: const <String?>['sku_000', 'sku_001', null],
      ),
      CompartmentDef(
        index: 1,
        cells: const <String?>['sku_002', null, null],
        // A hidden product the player never reveals in a status-only win.
        hidden: const <String>['sku_050'],
      ),
      for (var index = 2; index < 15; index += 1)
        CompartmentDef(index: index, cells: const <String?>[null, null, null]),
    ],
  );
}
