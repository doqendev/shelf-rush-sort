import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../application/boosters/booster_inventory_service.dart';
import '../application/game_session/game_session_controller.dart';
import '../application/game_session/game_session_state.dart';
import '../domain/boosters/booster_def.dart';
import '../domain/boosters/booster_rules.dart';
import '../domain/core/value_objects.dart';
import '../domain/game/board_state.dart';
import '../domain/game/objective.dart';
import '../infrastructure/save/save_repository.dart';
import '../presentation/flame/shelf_rush_game.dart';

/// Debug-only automation surface for QA builds. Exposes deterministic entry
/// points (navigate, drive moves, read full game+economy state) so a reviewer
/// can play AND verify the canvas game headlessly instead of judging only
/// screenshots.
///
/// Wired to `window.shelfRushQa` on web by [installQaBridge]; only installed in
/// non-production builds (SHELF_RUSH_ENV=dev|qa). Mutators return a structured
/// result so automation never has to infer success from before/after diffs.
class QaBridge {
  QaBridge._();

  static final QaBridge instance = QaBridge._();

  /// App-level handles, set once at bootstrap.
  ProviderContainer? container;
  GoRouter? router;

  /// Active game handles, set by GameScreen while a level is open.
  GameSessionController? controller;
  ShelfRushGame? game;
  void Function(int level)? reloadLevel;

  void bindGame(
    GameSessionController controller,
    ShelfRushGame game,
    void Function(int level) reloadLevel,
  ) {
    this.controller = controller;
    this.game = game;
    this.reloadLevel = reloadLevel;
  }

  void unbindGame(GameSessionController controller) {
    if (identical(this.controller, controller)) {
      this.controller = null;
      game = null;
      reloadLevel = null;
    }
  }

  // ---- Navigation / lifecycle ------------------------------------------------

  /// Loads [level] in a FRESH session — even if already on that level (so the
  /// same-level reload trap can't invalidate a flow; third-pass hands-on P0.3).
  Map<String, Object?> goToLevel(int level) {
    final void Function(int)? reload = reloadLevel;
    if (reload != null) {
      reload(level);
    } else {
      router?.go('/?level=$level');
    }
    return <String, Object?>{'ok': true, 'level': level};
  }

  Map<String, Object?> restartLevel() {
    final GameSessionController? c = controller;
    final void Function(int)? reload = reloadLevel;
    if (c == null || reload == null) {
      return <String, Object?>{'ok': false, 'reason': 'no_active_game'};
    }
    reload(c.state.level.levelNumber);
    return <String, Object?>{'ok': true, 'level': c.state.level.levelNumber};
  }

  Map<String, Object?> resetSave() {
    final ProviderContainer? c = container;
    if (c == null) {
      return <String, Object?>{'ok': false, 'reason': 'no_container'};
    }
    final int startingCoins = c
        .read(contentServiceProvider)
        .content
        .economy
        .startingCoins;
    final PlayerSave fresh = PlayerSave.newPlayer(
      playerId: 'qa_local',
      startingCoins: startingCoins,
    );
    c.read(playerSaveProvider.notifier).state = fresh;
    c.read(saveRepositoryProvider).save(fresh);
    // Restart the active level so the visible board reflects the fresh save.
    final GameSessionController? ctrl = controller;
    final void Function(int)? reload = reloadLevel;
    if (ctrl != null && reload != null) {
      reload(ctrl.state.level.levelNumber);
    }
    return <String, Object?>{'ok': true};
  }

  Map<String, Object?> pause() {
    final bool ok = controller != null;
    controller?.setPaused(true);
    return <String, Object?>{'ok': ok};
  }

  Map<String, Object?> resume() {
    final bool ok = controller != null;
    controller?.setPaused(false);
    return <String, Object?>{'ok': ok};
  }

  // ---- Driving the board (drives the controller directly — no pixel math, so
  // it is deterministic and respects the same rules as real input) ------------

  Map<String, Object?> tapCell(int compartment, int cell) {
    final GameSessionController? c = controller;
    if (c == null) {
      return <String, Object?>{'ok': false, 'reason': 'no_active_game'};
    }
    c.selectCell(CellAddress.fromCompartmentIndex(compartment, cell));
    return <String, Object?>{
      'ok': true,
      'selectedCell': c.state.selectedCell?.key,
    };
  }

  Map<String, Object?> dragCellToCell(
    int fromCompartment,
    int fromCell,
    int toCompartment,
    int toCell,
  ) {
    final GameSessionController? c = controller;
    if (c == null) {
      return <String, Object?>{'ok': false, 'reason': 'no_active_game'};
    }
    final int beforeMoves = c.state.moveCount;
    c.selectCell(CellAddress.fromCompartmentIndex(fromCompartment, fromCell));
    c.placeSelectedAt(CellAddress.fromCompartmentIndex(toCompartment, toCell));
    return <String, Object?>{
      'ok': c.state.moveCount > beforeMoves,
      'moveCount': c.state.moveCount,
      'status': c.state.status.name,
      'visibleProductCount': c.state.board.visibleProductCount,
    };
  }

  Map<String, Object?> useBooster(String kind) {
    final GameSessionController? c = controller;
    if (c == null) {
      return <String, Object?>{'ok': false, 'reason': 'no_active_game'};
    }
    BoosterKind? booster;
    for (final BoosterKind value in BoosterKind.values) {
      if (value.name == kind) {
        booster = value;
        break;
      }
    }
    if (booster == null) {
      return <String, Object?>{'ok': false, 'reason': 'unknown_booster'};
    }
    // Mirror the real UI flow: must own one, and consume only if it applies.
    final ProviderContainer? ct = container;
    if (ct != null) {
      const BoosterInventoryService inventory = BoosterInventoryService();
      final PlayerSave save = ct.read(playerSaveProvider);
      final int beforeCount = save.boosters[booster] ?? 0;
      if (!inventory.canUse(save, booster)) {
        return _boosterResult(
          kind,
          false,
          'not_owned',
          beforeCount,
          beforeCount,
        );
      }
      final BoosterAvailability availability = c.canUseBooster(booster);
      if (!availability.canUse) {
        return _boosterResult(
          kind,
          false,
          availability.reason,
          beforeCount,
          beforeCount,
        );
      }
      final PlayerSave consumed = inventory.consume(save, booster);
      ct.read(playerSaveProvider.notifier).state = consumed;
      ct.read(saveRepositoryProvider).save(consumed);
      c.useBooster(booster);
      final int afterCount = ct.read(playerSaveProvider).boosters[booster] ?? 0;
      return _boosterResult(kind, true, 'used', beforeCount, afterCount);
    }
    c.useBooster(booster);
    return <String, Object?>{'ok': true, 'kind': kind, 'reason': 'used'};
  }

  Map<String, Object?> _boosterResult(
    String kind,
    bool ok,
    String? reason,
    int beforeCount,
    int afterCount,
  ) {
    return <String, Object?>{
      'ok': ok,
      'kind': kind,
      'reason': reason,
      'consumed': afterCount < beforeCount,
      'beforeCount': beforeCount,
      'afterCount': afterCount,
    };
  }

  // ---- Inspection ------------------------------------------------------------

  bool isPresentationBusy() => game?.isPresentationBusy ?? false;

  /// Whether the bridge is fully wired. The provider container is now bound at
  /// app root, so this is true before the first level opens; manifest runners
  /// should poll it before resetSave()/getState() (hands-on v3 P1.1).
  Map<String, Object?> ready() {
    return <String, Object?>{
      'ok': container != null,
      'container': container != null,
      'router': router != null,
      'activeGame': controller != null,
    };
  }

  Map<String, Object?> getState() {
    final GameSessionController? c = controller;
    if (c == null) {
      return <String, Object?>{'status': 'no_active_game'};
    }
    final GameSessionState s = c.state;
    final Map<String, int> boosterCounts = <String, int>{};
    int coins = 0;
    int stars = 0;
    Map<String, Object?> levelStars = const <String, Object?>{};
    List<Object?> discovered = const <Object?>[];
    List<Object?> ledgerKeys = const <Object?>[];
    bool firstCompletion = false;
    final ProviderContainer? container = this.container;
    if (container != null) {
      final PlayerSave save = container.read(playerSaveProvider);
      save.boosters.forEach((BoosterKind kind, int count) {
        boosterCounts[kind.name] = count;
      });
      coins = save.coins;
      stars = save.progress.stars;
      levelStars = <String, Object?>{
        for (final MapEntry<String, int> e in save.progress.levelStars.entries)
          e.key: e.value,
      };
      discovered =
          (save.collections['discovered'] as List<Object?>?) ??
          const <Object?>[];
      ledgerKeys = save.ledger.keys.toList();
      firstCompletion = s.level.levelNumber > save.highestLevelCompleted;
    }
    final int? timerSeconds = s.level.timeLimitSeconds == null
        ? null
        : (s.level.timeLimitSeconds! - s.timer.elapsed.inSeconds);
    final bool won = s.status == GameSessionStatus.won;
    // The objective strip counts hidden products too; mirror it so the bridge's
    // remaining text matches the player-facing HUD (hands-on v4 P2.1).
    final int hiddenRemaining = s.board.compartments.fold<int>(
      0,
      (int sum, CompartmentState c) => sum + c.hiddenStack.length,
    );
    final int totalRemaining = s.board.visibleProductCount + hiddenRemaining;
    return <String, Object?>{
      'level': s.level.levelNumber,
      'levelId': s.level.id,
      'status': s.status.name,
      'moveCount': s.moveCount,
      'visibleProductCount': s.board.visibleProductCount,
      'totalRemainingProductCount': totalRemaining,
      'objectiveType': s.objective.requirement.type.name,
      'objectiveText': _objectiveText(s),
      'remainingText': '$totalRemaining left',
      'selectedCell': s.selectedCell?.key,
      'failReason': s.failReason.name,
      'timerSeconds': timerSeconds,
      'coins': coins,
      'stars': stars,
      'levelStars': levelStars,
      'discoveredSkus': discovered,
      'ledgerKeys': ledgerKeys,
      'boosterCounts': boosterCounts,
      'canRevive': c.canRevive,
      // first completion still pending a coin grant -> the win panel will show
      // the coin row + Double option (third-pass hands-on P2.2).
      'winRewardAvailable': won && firstCompletion,
      'doubleRewardAvailable': won && firstCompletion,
      'presentationBusy': game?.isPresentationBusy ?? false,
      // The hint booster's suggested move and the authored star thresholds, so
      // a reviewer can verify hint output and the 3-star path (v3 P2.4 / P1.5).
      'suggestedMove': s.suggestedMove == null
          ? null
          : <String, Object?>{
              'source': s.suggestedMove!.source.key,
              'target': s.suggestedMove!.target.key,
            },
      'score': s.level.score == null
          ? null
          : <String, Object?>{
              'threeStarMoves': s.level.score!.threeStarMoves,
              'twoStarMoves': s.level.score!.twoStarMoves,
            },
      'board': <Object?>[
        for (final CompartmentState compartment in s.board.compartments)
          <String, Object?>{
            'index': compartment.index,
            'locked': compartment.locked,
            'decorative': compartment.decorative,
            'interactable': compartment.interactable,
            'cells': <Object?>[
              for (final ShelfCell shelfCell in compartment.frontCells)
                shelfCell.product?.skuId,
            ],
          },
      ],
    };
  }

  Map<String, Object?> viewportInfo() {
    final ShelfRushGame? g = game;
    return <String, Object?>{
      'gameWidth': g?.size.x,
      'gameHeight': g?.size.y,
      'hasActiveGame': g != null,
    };
  }

  String _objectiveText(GameSessionState s) {
    return switch (s.objective.requirement.type) {
      ObjectiveType.clearAll => 'Put 3 matching products on one shelf',
      ObjectiveType.clearSkuTargets => 'Sort the requested products',
      _ => s.objective.requirement.type.name,
    };
  }
}
