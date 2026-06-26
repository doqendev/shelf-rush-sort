import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../application/boosters/booster_inventory_service.dart';
import '../../application/content/content_service.dart';
import '../../application/game_session/game_session_controller.dart';
import '../../application/game_session/game_session_state.dart';
import '../../application/monetization/monetization_service.dart';
import '../../application/progression/level_completion_service.dart';
import '../../application/progression/reward_service.dart';
import '../../domain/boosters/booster_def.dart';
import '../../domain/boosters/booster_rules.dart';
import '../../domain/content/level_def.dart';
import '../../infrastructure/analytics/analytics_event.dart';
import '../../infrastructure/analytics/analytics_service.dart';
import '../../infrastructure/save/save_repository.dart';
import '../design/game_colors.dart';
import '../flame/shelf_rush_game.dart';
import 'cozy/cozy_widgets.dart';
import 'gameplay/game_scaffold.dart';
import 'gameplay/game_viewport.dart';
import 'gameplay/pause_sheet.dart';
import 'overlays/loss_panel.dart';
import 'overlays/win_panel.dart';

final class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.initialLevel});

  final int initialLevel;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

final class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  GameSessionController? _controller;
  ShelfRushGame? _game;
  StreamSubscription<GameSessionState>? _subscription;
  GameSessionState? _session;
  // Presentation settle: the win/loss overlay is held back until the final
  // clear has been seen (review P1.4 / section 16.2), keyed per attempt.
  bool _endOverlayVisible = false;
  String? _endOverlayAttempt;
  // Coins actually granted for the current win (0 on a replay) — the win panel
  // shows this, never a recomputed theoretical reward (third-pass audit P0.2).
  int _winCoinsGranted = 0;
  late int _levelNumber;
  final Set<String> _committedWinAttempts = <String>{};
  final Set<String> _doubleRewardedAttempts = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final GameSessionController? controller = _controller;
    final ShelfRushGame? game = _game;
    if (controller == null || game == null) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      // Only auto-resume when the game screen is the visible, top-most route
      // (not behind a pause sheet, settings page, ad, or ended overlay).
      final bool onTop = ModalRoute.of(context)?.isCurrent ?? false;
      if (mounted && onTop && !controller.state.isEnded) {
        controller.setPaused(false);
        game.resumeEngine();
      }
    } else {
      controller.setPaused(true);
      game.pauseEngine();
    }
  }

  @override
  Widget build(BuildContext context) {
    final GameSessionState? session = _session;
    final ShelfRushGame? game = _game;
    if (session == null || game == null) {
      return const _CozyLoading();
    }
    final PlayerSave save = ref.watch(playerSaveProvider);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GameScaffold(
              session: session,
              viewport: GameViewport(game: game),
              onPause: _showPauseSheet,
              onUseBooster: _useBooster,
              boosterCounts: save.boosters,
            ),
          ),
          if (session.status == GameSessionStatus.won && _endOverlayVisible)
            WinPanel(
              session: session,
              coinsGranted: _winCoinsGranted,
              onNext: () => _completeAndNext(doubleReward: false),
              onDoubleReward: () => _completeAndNext(doubleReward: true),
              onRetry: () => _loadLevel(_levelNumber),
            ),
          if (session.status == GameSessionStatus.failed && _endOverlayVisible)
            LossPanel(
              session: session,
              canRevive: _controller?.canRevive ?? false,
              onRetry: () => _loadLevel(_levelNumber),
              onRevive: _reviveWithRewardedAd,
            ),
        ],
      ),
    );
  }

  void _useBooster(BoosterKind kind) {
    final GameSessionController? controller = _controller;
    if (controller == null || controller.state.isEnded) {
      return;
    }
    const BoosterInventoryService inventory = BoosterInventoryService();
    final PlayerSave save = ref.read(playerSaveProvider);
    if (!inventory.canUse(save, kind)) {
      // Out of this booster — send the player to the shop to get more.
      context.push('/shop');
      return;
    }
    // Don't consume inventory for a booster that can't do anything in the
    // current context (third-pass audit P0.1) — preflight the domain first.
    final BoosterAvailability availability = controller.canUseBooster(kind);
    if (!availability.canUse) {
      _showBoosterUnavailable(availability.reason);
      return;
    }
    final PlayerSave consumed = inventory.consume(save, kind);
    ref.read(playerSaveProvider.notifier).state = consumed;
    unawaited(ref.read(saveRepositoryProvider).save(consumed));
    controller.useBooster(kind);
  }

  void _showBoosterUnavailable(String? reason) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_boosterUnavailableMessage(reason)),
          duration: const Duration(milliseconds: 1800),
        ),
      );
  }

  String _boosterUnavailableMessage(String? reason) {
    return switch (reason) {
      'freeze_needs_timer' => "There's no timer to freeze on this level.",
      'no_hidden_to_reveal' => 'No hidden products to reveal here.',
      'shuffle_needs_products' ||
      'shuffle_would_not_improve' => "Shuffling won't help right now.",
      'no_legal_hint' => 'No useful move to hint at.',
      'hammer_needs_selection' => 'Tap a product first, then the hammer.',
      'hammer_invalid_cell' ||
      'hammer_empty_cell' => 'Pick a product to remove.',
      'extra_shelf_unavailable' => "Can't add a shelf right now.",
      'no_active_conveyor' => 'No moving lane to slow here.',
      _ => "That booster can't be used right now.",
    };
  }

  void _scheduleEndOverlay(GameSessionState state) {
    final bool ended =
        state.status == GameSessionStatus.won ||
        state.status == GameSessionStatus.failed;
    if (!ended || _endOverlayAttempt == state.attemptId) {
      return;
    }
    // Hold the cleared board and let the final celebration play before the
    // win/loss panel arrives (review P1.4 — don't interrupt the final moment).
    // Rather than a fixed delay, wait until the board's FX/animations actually
    // settle, bounded by a min hold and a max fallback (audit M2 / section 7).
    _endOverlayAttempt = state.attemptId;
    _awaitPresentationSettled(state.attemptId, elapsed: Duration.zero);
  }

  void _awaitPresentationSettled(
    String attemptId, {
    required Duration elapsed,
  }) {
    const Duration step = Duration(milliseconds: 80);
    const Duration minHold = Duration(milliseconds: 360);
    const Duration maxHold = Duration(milliseconds: 1600);
    Future<void>.delayed(step, () {
      if (!mounted) {
        return;
      }
      final GameSessionState? current = _controller?.state;
      final bool stillEnded =
          current != null &&
          current.attemptId == attemptId &&
          (current.status == GameSessionStatus.won ||
              current.status == GameSessionStatus.failed);
      if (!stillEnded) {
        // Reloaded or revived before the overlay showed — abandon this wait.
        return;
      }
      final Duration now = elapsed + step;
      final bool busy = _game?.isPresentationBusy ?? false;
      if (now < minHold || (busy && now < maxHold)) {
        _awaitPresentationSettled(attemptId, elapsed: now);
        return;
      }
      setState(() => _endOverlayVisible = true);
    });
  }

  void _showPauseSheet() {
    // Pause both the simulation (timer + lanes) and the Flame engine while the
    // sheet is open. Resume ONLY when the game screen is the top-most route
    // again — so opening Settings/Debug from pause keeps the game paused behind
    // them and resumes on return, never running underneath another route
    // (second-pass audit P0.3).
    final ShelfRushGame? pausedGame = _game;
    final GameSessionController? pausedController = _controller;
    pausedController?.setPaused(true);
    pausedGame?.pauseEngine();

    var resumed = false;
    void resumeGame() {
      if (resumed || !mounted) {
        return;
      }
      final bool onTop = ModalRoute.of(context)?.isCurrent ?? false;
      final bool sameSession =
          identical(pausedGame, _game) &&
          identical(pausedController, _controller);
      if (onTop &&
          sameSession &&
          pausedController != null &&
          !pausedController.state.isEnded) {
        resumed = true;
        pausedController.setPaused(false);
        pausedGame?.resumeEngine();
      }
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: GameColors.bgGreen,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext sheetContext) {
        void closeThen(VoidCallback action) {
          Navigator.of(sheetContext).pop();
          action();
        }

        // Close the sheet, open a route over the (still-paused) game, and
        // resume only once that route is popped and the game is current again.
        void openRouteThenResume(String location) {
          Navigator.of(sheetContext).pop();
          unawaited(context.push(location).then((_) => resumeGame()));
        }

        return PauseSheet(
          onResume: () => Navigator.of(sheetContext).pop(),
          onRestart: () => closeThen(() => _loadLevel(_levelNumber)),
          onSettings: () => openRouteThenResume('/settings'),
          onExitToMap: () => closeThen(() => context.go('/home')),
          onDebug: ref.watch(environmentProvider).debugToolsEnabled
              ? () => openRouteThenResume('/debug/analytics')
              : null,
        );
      },
    ).whenComplete(resumeGame);
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
      audio: ref.read(audioServiceProvider),
      haptics: ref.read(hapticsServiceProvider),
      analytics: analytics,
      reduceMotion: ref.read(playerSaveProvider).reduceMotion,
    );
    _subscription = controller.states.listen((GameSessionState state) {
      if (mounted) {
        setState(() {
          _session = state;
        });
      }
      if (state.status == GameSessionStatus.won) {
        unawaited(_commitWinIfNeeded(state));
      }
      _scheduleEndOverlay(state);
    });
    setState(() {
      _levelNumber = levelNumber;
      _controller = controller;
      _game = game;
      _session = controller.state;
      _endOverlayVisible = false;
      _endOverlayAttempt = null;
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
    await _commitWinIfNeeded(session);
    final AnalyticsService analytics = ref.read(analyticsServiceProvider);
    if (doubleReward) {
      final MonetizationService monetization = MonetizationService(
        ads: ref.read(adsServiceProvider),
        analytics: analytics,
      );
      final result = await monetization.requestDoubleReward(session.level);
      if (!result.completed) {
        return;
      }
      if (_doubleRewardedAttempts.add(session.attemptId)) {
        final PlayerSave before = ref.read(playerSaveProvider);
        final RewardGrant reward = const RewardService().levelWinReward(
          session.level.levelNumber,
        );
        final PlayerSave rewarded = const LevelCompletionService()
            .commitDoubleReward(
              save: before,
              level: session.level,
              reward: reward,
              adTransactionId: session.attemptId,
            );
        ref.read(playerSaveProvider.notifier).state = rewarded;
        unawaited(ref.read(saveRepositoryProvider).save(rewarded));
        unawaited(
          analytics.track(
            AnalyticsEvent(
              name: 'economy_transaction',
              parameters: <String, Object?>{
                'level_id': session.level.id,
                'type': 'grant',
                'currency': 'coins',
                'amount': rewarded.coins - before.coins,
                'reason': 'level_win_double_reward',
                'balance': rewarded.coins,
              },
            ),
          ),
        );
      }
    }
    final int maxLevel = ref
        .read(contentServiceProvider)
        .content
        .levelPack
        .levels
        .length;
    final int nextLevel = (session.level.levelNumber + 1).clamp(1, maxLevel);
    _loadLevel(nextLevel);
  }

  Future<void> _commitWinIfNeeded(GameSessionState session) async {
    if (session.status != GameSessionStatus.won ||
        !_committedWinAttempts.add(session.attemptId)) {
      return;
    }
    final PlayerSave before = ref.read(playerSaveProvider);
    final RewardGrant reward = const RewardService().levelWinReward(
      session.level.levelNumber,
    );
    final LevelCompletionResult result = const LevelCompletionService()
        .commitWin(
          save: before,
          level: session.level,
          session: session,
          reward: reward,
        );
    final PlayerSave committed = result.save;
    ref.read(playerSaveProvider.notifier).state = committed;
    await ref.read(saveRepositoryProvider).save(committed);
    final int granted = result.coinsGranted;
    _winCoinsGranted = granted;
    if (granted > 0) {
      await ref
          .read(analyticsServiceProvider)
          .track(
            AnalyticsEvent(
              name: 'economy_transaction',
              parameters: <String, Object?>{
                'level_id': session.level.id,
                'type': 'grant',
                'currency': 'coins',
                'amount': granted,
                'reason': reward.reason,
                'balance': committed.coins,
              },
            ),
          );
    }
  }

  Future<void> _reviveWithRewardedAd() async {
    final GameSessionState? session = _session;
    final GameSessionController? controller = _controller;
    if (session == null || controller == null || !controller.canRevive) {
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

class _CozyLoading extends StatelessWidget {
  const _CozyLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.bgMint,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CozyTitle(
              'SHELF\nRUSH',
              fontSize: 56,
              strokeWidth: 6,
              height: 0.86,
            ),
            const SizedBox(height: 24),
            Image.asset(
              cozyAsset('reward/flower-vase.png'),
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  const SizedBox(width: 120, height: 120),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: GameColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
