import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../application/content/content_service.dart';
import '../../application/economy/economy_service.dart';
import '../../application/game_session/game_session_controller.dart';
import '../../application/game_session/game_session_state.dart';
import '../../application/monetization/monetization_service.dart';
import '../../application/progression/progression_service.dart';
import '../../application/progression/reward_service.dart';
import '../../domain/content/level_def.dart';
import '../../infrastructure/analytics/analytics_event.dart';
import '../../infrastructure/analytics/analytics_service.dart';
import '../../infrastructure/save/save_repository.dart';
import '../flame/shelf_rush_game.dart';
import 'hud/hud_overlay.dart';
import 'overlays/loss_panel.dart';
import 'overlays/win_panel.dart';

final class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.initialLevel});

  final int initialLevel;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

final class _GameScreenState extends ConsumerState<GameScreen> {
  GameSessionController? _controller;
  ShelfRushGame? _game;
  StreamSubscription<GameSessionState>? _subscription;
  GameSessionState? _session;
  late int _levelNumber;

  @override
  void initState() {
    super.initState();
    _levelNumber = widget.initialLevel;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLevel(_levelNumber);
    });
  }

  @override
  void didUpdateWidget(covariant GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLevel != widget.initialLevel) {
      _levelNumber = widget.initialLevel;
      _loadLevel(_levelNumber);
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PlayerSave save = ref.watch(playerSaveProvider);
    final GameSessionState? session = _session;
    final ShelfRushGame? game = _game;
    if (session == null || game == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: GameWidget(game: game)),
          SafeArea(
            child: HudOverlay(
              session: session,
              save: save,
              onMap: () => context.push('/map'),
              onShop: () => context.push('/shop'),
              onSettings: () => context.push('/settings'),
              onRetry: () => _loadLevel(_levelNumber),
              onDebug: ref.watch(environmentProvider).debugToolsEnabled
                  ? () => context.push('/debug/analytics')
                  : null,
            ),
          ),
          if (session.status == GameSessionStatus.won)
            WinPanel(
              session: session,
              onNext: () => _completeAndNext(doubleReward: false),
              onDoubleReward: () => _completeAndNext(doubleReward: true),
              onRetry: () => _loadLevel(_levelNumber),
            ),
          if (session.status == GameSessionStatus.failed)
            LossPanel(
              session: session,
              onRetry: () => _loadLevel(_levelNumber),
              onRevive: _reviveWithRewardedAd,
            ),
        ],
      ),
    );
  }

  void _loadLevel(int requestedLevel) {
    final Stopwatch loadTimer = Stopwatch()..start();
    final ContentService contentService = ref.read(contentServiceProvider);
    final int maxLevel = contentService.content.levelPack.levels.length;
    final int levelNumber = requestedLevel.clamp(1, maxLevel);
    final LevelDef level = ref
        .read(remoteConfigServiceProvider)
        .applyToLevel(contentService.levelByNumber(levelNumber));
    unawaited(_subscription?.cancel());
    _controller?.dispose();

    final AnalyticsService analytics = ref.read(analyticsServiceProvider);
    final GameSessionController controller = GameSessionController(
      level: level,
      analytics: analytics,
    );
    final ShelfRushGame game = ShelfRushGame(
      controller: controller,
      productCatalog: contentService.content.productCatalog,
    );
    _subscription = controller.states.listen((GameSessionState state) {
      if (mounted) {
        setState(() {
          _session = state;
        });
      }
    });
    setState(() {
      _levelNumber = levelNumber;
      _controller = controller;
      _game = game;
      _session = controller.state;
    });
    loadTimer.stop();
    unawaited(
      analytics.track(
        AnalyticsEvent(
          name: 'performance_level_load',
          essential: true,
          parameters: <String, Object?>{
            'level_id': level.id,
            'load_time_ms': loadTimer.elapsedMilliseconds,
            'first_playable_ms': loadTimer.elapsedMilliseconds,
            'device_tier': ref.read(deviceInfoServiceProvider).deviceTier,
          },
        ),
      ),
    );
  }

  Future<void> _completeAndNext({required bool doubleReward}) async {
    final GameSessionState? session = _session;
    if (session == null) {
      return;
    }
    final AnalyticsService analytics = ref.read(analyticsServiceProvider);
    var rewardMultiplier = 1;
    if (doubleReward) {
      final MonetizationService monetization = MonetizationService(
        ads: ref.read(adsServiceProvider),
        analytics: analytics,
      );
      final result = await monetization.requestDoubleReward(session.level);
      if (!result.completed) {
        return;
      }
      rewardMultiplier = 2;
    }
    final PlayerSave save = ref.read(playerSaveProvider);
    final ProgressionService progression = const ProgressionService();
    final RewardService rewards = const RewardService();
    final EconomyService economy = const EconomyService();
    final reward = rewards.levelWinReward(session.level.levelNumber);
    final int coinsGranted = reward.coins * rewardMultiplier;
    final PlayerSave updated = progression
        .onLevelWon(save, session.level)
        .copyWith(lastSeenAt: DateTime.now().toUtc());
    final PlayerSave rewarded = economy.grantCoinsToSave(
      updated,
      coinsGranted,
      doubleReward ? 'level_win_double_reward' : reward.reason,
      sourceId:
          '${session.level.id}_${doubleReward ? 'double_reward' : 'win_reward'}',
    );
    unawaited(
      analytics.track(
        AnalyticsEvent(
          name: 'economy_transaction',
          parameters: <String, Object?>{
            'level_id': session.level.id,
            'type': 'grant',
            'currency': 'coins',
            'amount': coinsGranted,
            'reason': doubleReward ? 'level_win_double_reward' : reward.reason,
            'balance': rewarded.coins,
          },
        ),
      ),
    );
    ref.read(playerSaveProvider.notifier).state = rewarded;
    unawaited(ref.read(saveRepositoryProvider).save(rewarded));
    final int maxLevel = ref
        .read(contentServiceProvider)
        .content
        .levelPack
        .levels
        .length;
    final int nextLevel = (session.level.levelNumber + 1).clamp(1, maxLevel);
    _loadLevel(nextLevel);
  }

  Future<void> _reviveWithRewardedAd() async {
    final GameSessionState? session = _session;
    final GameSessionController? controller = _controller;
    if (session == null || controller == null) {
      return;
    }
    final MonetizationService monetization = MonetizationService(
      ads: ref.read(adsServiceProvider),
      analytics: ref.read(analyticsServiceProvider),
    );
    final result = await monetization.requestRewardedRevive(session.level);
    if (result.completed) {
      controller.revive();
    }
  }
}
