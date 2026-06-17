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

    final PlayerSave first = service.commitWin(
      save: save,
      level: level,
      session: session,
      reward: reward,
    );
    final PlayerSave second = service.commitWin(
      save: first,
      level: level,
      session: session,
      reward: reward,
    );

    expect(first.highestLevelCompleted, 1);
    expect(first.coins, 52);
    expect(second.coins, 52);
    expect(second.ledger, hasLength(first.ledger.length));
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
