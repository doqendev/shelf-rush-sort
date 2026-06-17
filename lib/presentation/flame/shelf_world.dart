import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../application/game_session/game_session_controller.dart';
import '../../application/game_session/game_session_state.dart';
import '../../domain/content/product_def.dart';
import '../../domain/core/value_objects.dart';
import '../../domain/game/board_state.dart';
import '../../domain/moving_lanes/moving_lane_state.dart';
import 'board/board_layout_calculator.dart';
import 'board/cell_target_component.dart';
import 'board/compartment_component.dart';
import 'board/hidden_preview_component.dart';
import 'board/product_component.dart';
import 'fx/fx_director.dart';
import 'input/input_router.dart';
import 'lanes/moving_lane_component.dart';

final class ShelfWorld extends World {
  ShelfWorld({
    required this.controller,
    required this.productCatalog,
    required BoardLayout initialLayout,
    this.layoutCalculator = const BoardLayoutCalculator(),
    this.fxDirector = const FxDirector(),
  }) : inputRouter = InputRouter(controller: controller, layout: initialLayout),
       _layout = initialLayout,
       _state = controller.state;

  final GameSessionController controller;
  final ProductCatalog productCatalog;
  final BoardLayoutCalculator layoutCalculator;
  final FxDirector fxDirector;
  final InputRouter inputRouter;
  late final StreamSubscription<GameSessionState> _subscription;
  BoardLayout _layout;
  GameSessionState _state;
  bool _rebuilding = false;
  bool _pendingRebuild = false;

  @override
  Future<void> onLoad() async {
    _subscription = controller.states.listen(syncState);
    await rebuild();
  }

  @override
  void onRemove() {
    unawaited(_subscription.cancel());
    super.onRemove();
  }

  void resize(Vector2 size) {
    _layout = layoutCalculator.calculate(
      size,
      hasLane: _state.lanes.isNotEmpty,
    );
    inputRouter.layout = _layout;
    unawaited(rebuild());
  }

  void syncState(GameSessionState state) {
    _state = state;
    fxDirector.handleEvents(state.events);
    unawaited(rebuild());
  }

  Future<void> rebuild() async {
    if (_rebuilding) {
      _pendingRebuild = true;
      return;
    }
    _rebuilding = true;
    do {
      _pendingRebuild = false;
      removeAll(children.toList());
      await _addBoard();
      await _addLanes();
    } while (_pendingRebuild);
    _rebuilding = false;
  }

  Future<void> _addBoard() async {
    for (final CompartmentState compartment in _state.board.compartments) {
      final Rect compartmentRect = _layout.compartmentRect(compartment.index);
      await add(
        CompartmentComponent(
          locked: compartment.locked,
          decorative: compartment.decorative,
          position: Vector2(compartmentRect.left, compartmentRect.top),
          size: Vector2(compartmentRect.width, compartmentRect.height),
        ),
      );
      if (compartment.hasHiddenProducts) {
        await add(
          HiddenPreviewComponent(
            count: compartment.hiddenStack.length,
            position: Vector2(
              compartmentRect.left + 10,
              compartmentRect.top + 8,
            ),
            size: Vector2(compartmentRect.width - 20, compartmentRect.height),
          ),
        );
      }
      for (var cell = 0; cell < cellsPerCompartment; cell += 1) {
        final CellAddress address = compartment.addressForCell(cell);
        final Rect cellRect = _layout.cellRect(address);
        final ShelfCell shelfCell = compartment.cellAt(cell);
        if (shelfCell.product == null) {
          await add(
            CellTargetComponent(
              address: address,
              inputRouter: inputRouter,
              highlighted:
                  _state.selectedCell != null ||
                  _state.laneHoldingProduct != null,
              position: Vector2(cellRect.left, cellRect.top),
              size: Vector2(cellRect.width, cellRect.height),
            ),
          );
          continue;
        }
        final ProductDef? productDef = productCatalog.bySku(
          shelfCell.product!.skuId,
        );
        if (productDef == null) {
          continue;
        }
        await add(
          ProductComponent(
            address: address,
            productDef: productDef,
            inputRouter: inputRouter,
            selected: _state.selectedCell == address,
            position: Vector2(cellRect.left, cellRect.top),
            size: Vector2(cellRect.width, cellRect.height),
          ),
        );
      }
    }
  }

  Future<void> _addLanes() async {
    if (_state.lanes.isEmpty) {
      return;
    }
    final Rect laneRect = _layout.laneRect;
    for (final MovingLaneState lane in _state.lanes) {
      await add(
        MovingLaneComponent(
          lane: lane,
          productCatalog: productCatalog,
          inputRouter: inputRouter,
          position: Vector2(laneRect.left, laneRect.top),
          size: Vector2(laneRect.width, laneRect.height),
        ),
      );
    }
  }
}
