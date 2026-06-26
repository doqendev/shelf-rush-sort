import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../application/game_session/game_session_controller.dart';
import '../application/game_session/game_session_state.dart';
import '../domain/boosters/booster_def.dart';
import '../domain/core/value_objects.dart';
import '../domain/game/board_state.dart';
import '../domain/game/objective.dart';
import '../infrastructure/save/save_repository.dart';
import '../presentation/flame/shelf_rush_game.dart';

/// Debug-only automation surface for QA builds. Exposes deterministic entry
/// points (navigate, drive moves, read full game state) so a reviewer can play
/// AND verify the canvas game headlessly instead of judging only screenshots.
///
/// Wired to `window.shelfRushQa` on web by [installQaBridge]; only installed in
/// non-production builds (SHELF_RUSH_ENV=dev|qa). All mutating calls are no-ops
/// when no game screen is active.
class QaBridge {
  QaBridge._();

  static final QaBridge instance = QaBridge._();

  /// App-level handles, set once at bootstrap.
  ProviderContainer? container;
  GoRouter? router;

  /// Active game handles, set by GameScreen while a level is open.
  GameSessionController? controller;
  ShelfRushGame? game;

  void bindGame(GameSessionController controller, ShelfRushGame game) {
    this.controller = controller;
    this.game = game;
  }

  void unbindGame(GameSessionController controller) {
    if (identical(this.controller, controller)) {
      this.controller = null;
      game = null;
    }
  }

  // ---- Navigation / lifecycle ------------------------------------------------

  void goToLevel(int level) => router?.go('/?level=$level');

  void resetSave() {
    final ProviderContainer? c = container;
    if (c == null) {
      return;
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
  }

  void pause() => controller?.setPaused(true);

  void resume() => controller?.setPaused(false);

  // ---- Driving the board (drives the controller directly — no pixel math, so
  // it is deterministic and respects the same rules as real input) ------------

  void tapCell(int compartment, int cell) {
    controller?.selectCell(CellAddress.fromCompartmentIndex(compartment, cell));
  }

  void dragCellToCell(
    int fromCompartment,
    int fromCell,
    int toCompartment,
    int toCell,
  ) {
    final GameSessionController? c = controller;
    if (c == null) {
      return;
    }
    c.selectCell(CellAddress.fromCompartmentIndex(fromCompartment, fromCell));
    c.placeSelectedAt(CellAddress.fromCompartmentIndex(toCompartment, toCell));
  }

  void useBooster(String kind) {
    final GameSessionController? c = controller;
    if (c == null) {
      return;
    }
    for (final BoosterKind value in BoosterKind.values) {
      if (value.name == kind) {
        c.useBooster(value);
        return;
      }
    }
  }

  // ---- Inspection ------------------------------------------------------------

  Map<String, Object?> getState() {
    final GameSessionController? c = controller;
    if (c == null) {
      return <String, Object?>{'status': 'no_active_game'};
    }
    final GameSessionState s = c.state;
    final Map<String, int> boosterCounts = <String, int>{};
    final ProviderContainer? container = this.container;
    if (container != null) {
      container.read(playerSaveProvider).boosters.forEach((
        BoosterKind kind,
        int count,
      ) {
        boosterCounts[kind.name] = count;
      });
    }
    final int? timerSeconds = s.level.timeLimitSeconds == null
        ? null
        : (s.level.timeLimitSeconds! - s.timer.elapsed.inSeconds);
    return <String, Object?>{
      'level': s.level.levelNumber,
      'levelId': s.level.id,
      'status': s.status.name,
      'moveCount': s.moveCount,
      'visibleProductCount': s.board.visibleProductCount,
      'objectiveType': s.objective.requirement.type.name,
      'objectiveText': _objectiveText(s),
      'remainingText': '${s.board.visibleProductCount} left',
      'selectedCell': s.selectedCell?.key,
      'failReason': s.failReason.name,
      'timerSeconds': timerSeconds,
      'boosterCounts': boosterCounts,
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
