import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../application/game_session/game_session_controller.dart';
import '../../application/game_session/game_session_state.dart';
import '../../domain/blockers/blocker_def.dart';
import '../../domain/content/product_def.dart';
import '../../domain/core/value_objects.dart';
import '../../domain/game/board_state.dart';
import '../../domain/game/move.dart';
import '../../domain/moving_lanes/moving_lane_state.dart';
import '../../infrastructure/platform/audio_service.dart';
import '../../infrastructure/platform/haptics_service.dart';
import 'board/board_layout_calculator.dart';
import 'board/cell_target_component.dart';
import 'board/dragged_product_component.dart';
import 'board/hidden_preview_component.dart';
import 'board/product_component.dart';
import 'board/rack_backdrop_component.dart';
import 'fx/clear_pop_component.dart';
import 'fx/fx_director.dart';
import 'input/input_router.dart';
import 'lanes/moving_lane_component.dart';

final class ShelfWorld extends World {
  ShelfWorld({
    required this.controller,
    required this.productCatalog,
    required BoardLayout initialLayout,
    this.audio = const SilentAudioService(),
    this.haptics = const FlutterHapticsService(enabled: false),
    this.reduceMotion = false,
    this.layoutCalculator = const BoardLayoutCalculator(),
    this.fxDirector = const FxDirector(),
  }) : inputRouter = InputRouter(controller: controller, layout: initialLayout),
       _layout = initialLayout,
       _state = controller.state {
    inputRouter
      ..onProductDragStarted = _startProductDragVisual
      ..onProductDragUpdated = _updateProductDragVisual
      ..onProductDragFinished = _finishProductDragVisual;
  }

  final GameSessionController controller;
  final ProductCatalog productCatalog;
  final AudioService audio;
  final HapticsService haptics;
  final bool reduceMotion;
  final BoardLayoutCalculator layoutCalculator;
  final FxDirector fxDirector;
  final InputRouter inputRouter;
  late final StreamSubscription<GameSessionState> _subscription;
  BoardLayout _layout;
  GameSessionState _state;
  bool _rebuilding = false;
  bool _pendingRebuild = false;
  String _boardSyncHash = '';
  _ProductDragVisual? _productDragVisual;
  DraggedProductComponent? _productDragComponent;
  final Map<String, MovingLaneComponent> _laneComponents =
      <String, MovingLaneComponent>{};

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
      laneDefs: _state.lanes.map((lane) => lane.def).toList(growable: false),
    );
    inputRouter.layout = _layout;
    unawaited(rebuild());
  }

  void syncState(GameSessionState state) {
    final String previousBoardHash = _boardSyncHash;
    _state = state;
    unawaited(
      fxDirector.handleEvents(
        state.events,
        world: this,
        audio: audio,
        haptics: haptics,
        reduceMotion: reduceMotion,
      ),
    );
    final String nextBoardHash = _currentBoardSyncHash();
    if (nextBoardHash != previousBoardHash) {
      unawaited(rebuild());
      return;
    }
    unawaited(_syncLanes());
  }

  Future<void> rebuild() async {
    if (_rebuilding) {
      _pendingRebuild = true;
      return;
    }
    _rebuilding = true;
    do {
      _pendingRebuild = false;
      removeAll(
        children
            .where(
              (Component child) =>
                  child != _productDragComponent && child is! ClearPopComponent,
            )
            .toList(),
      );
      _laneComponents.clear();
      await _addBoard();
      await _addLanes();
      await _syncProductDragComponent();
      _boardSyncHash = _currentBoardSyncHash();
    } while (_pendingRebuild);
    _rebuilding = false;
  }

  Future<void> _addBoard() async {
    final Rect rackRect = _layout.rackRect;
    final List<Rect> slotRects = <Rect>[
      for (int index = 0; index < compartmentCount; index += 1)
        _layout
            .compartmentRect(index)
            .shift(Offset(-rackRect.left, -rackRect.top)),
    ];
    await add(
      RackBackdropComponent(
        slotRects: slotRects,
        position: Vector2(rackRect.left, rackRect.top),
        size: Vector2(rackRect.width, rackRect.height),
      ),
    );
    for (final CompartmentState compartment in _state.board.compartments) {
      final Rect compartmentRect = _layout.compartmentRect(compartment.index);
      if (compartment.hasHiddenProducts) {
        await add(
          HiddenPreviewComponent(
            count: compartment.hiddenStack.length,
            mode: compartment.hiddenPreviewMode,
            revealed: compartment.hiddenPreviewRevealed,
            previewProducts: compartment.hiddenPreviewCells
                .map((SkuId? skuId) {
                  return skuId == null ? null : productCatalog.bySku(skuId);
                })
                .toList(growable: false),
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
              highlighted: _isLegalTarget(address),
              blocker: shelfCell.blocker,
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
        if (_productDragVisual?.source == address) {
          continue;
        }
        await add(
          ProductComponent(
            address: address,
            productDef: productDef,
            inputRouter: inputRouter,
            selected: _state.selectedCell == address,
            cellBlocker: shelfCell.blocker,
            productBlocker: shelfCell.product!.blocker,
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
    for (final MovingLaneState lane in _state.lanes) {
      final Rect laneRect = _layout.laneRectFor(lane.def.id);
      await add(
        _laneComponents[lane.def.id] = MovingLaneComponent(
          lane: lane,
          productCatalog: productCatalog,
          inputRouter: inputRouter,
          position: Vector2(laneRect.left, laneRect.top),
          size: Vector2(laneRect.width, laneRect.height),
        ),
      );
    }
  }

  Future<void> _syncLanes() async {
    for (final MovingLaneState lane in _state.lanes) {
      final MovingLaneComponent? component = _laneComponents[lane.def.id];
      if (component == null) {
        await _addLanes();
        return;
      }
      await component.syncLane(lane);
    }
  }

  void _startProductDragVisual(CellAddress address, Vector2 canvasPosition) {
    final ProductInstance? product = _state.board.productAt(address);
    if (product == null) {
      return;
    }
    final ProductDef? productDef = productCatalog.bySku(product.skuId);
    if (productDef == null) {
      return;
    }
    final Rect cellRect = _layout.cellRect(address);
    final ShelfCell shelfCell = _state.board.cellAt(address)!;
    final Vector2 origin = Vector2(cellRect.left, cellRect.top);
    _productDragVisual = _ProductDragVisual(
      source: address,
      productDef: productDef,
      cellBlocker: shelfCell.blocker,
      productBlocker: product.blocker,
      size: Vector2(cellRect.width, cellRect.height),
      grabOffset: canvasPosition - origin,
      position: origin,
    );
    unawaited(_syncProductDragComponent());
  }

  void _updateProductDragVisual(Vector2 canvasPosition) {
    final _ProductDragVisual? visual = _productDragVisual;
    if (visual == null) {
      return;
    }
    final Vector2 nextPosition = canvasPosition - visual.grabOffset;
    _productDragVisual = visual.copyWith(position: nextPosition);
    final DraggedProductComponent? component = _productDragComponent;
    if (component != null && component.isMounted) {
      component.position = nextPosition;
    } else {
      unawaited(_syncProductDragComponent());
    }
  }

  void _finishProductDragVisual(bool placed) {
    final _ProductDragVisual? visual = _productDragVisual;
    _productDragVisual = null;
    final DraggedProductComponent? component = _productDragComponent;
    if (component == null) {
      unawaited(rebuild());
      return;
    }
    if (placed || visual == null || reduceMotion) {
      _productDragComponent = null;
      component.removeFromParent();
      unawaited(rebuild());
      return;
    }
    // Invalid drop: spring the lifted product back to its source shelf, then
    // settle the board (P1.2 — a cancelled drag should animate home, not snap
    // back instantly).
    final Rect source = _layout.cellRect(visual.source);
    component.animateReturnTo(
      Vector2(source.left, source.top),
      onComplete: () {
        _productDragComponent = null;
        component.removeFromParent();
        unawaited(rebuild());
      },
    );
  }

  Future<void> _syncProductDragComponent() async {
    final _ProductDragVisual? visual = _productDragVisual;
    if (visual == null) {
      return;
    }
    final DraggedProductComponent? current = _productDragComponent;
    if (current != null && current.isMounted) {
      current.position = visual.position;
      return;
    }
    final DraggedProductComponent component = DraggedProductComponent(
      productDef: visual.productDef,
      cellBlocker: visual.cellBlocker,
      productBlocker: visual.productBlocker,
      position: visual.position,
      size: visual.size,
      reduceMotion: reduceMotion,
    );
    _productDragComponent = component;
    await add(component);
  }

  /// Plays a celebration burst over the shelf slot where a triple just cleared.
  /// FX components are preserved across board rebuilds until they self-remove.
  void playTripleClearFx(int compartmentIndex, int comboIndex) {
    final Rect rect = _layout.compartmentRect(compartmentIndex);
    final FutureOr<void> pending = add(
      ClearPopComponent(
        position: Vector2(rect.left, rect.top),
        size: Vector2(rect.width, rect.height),
        comboIndex: comboIndex,
      ),
    );
    if (pending is Future<void>) {
      unawaited(pending);
    }
  }

  bool _isLegalTarget(CellAddress target) {
    final CellAddress? selected = _state.selectedCell;
    if (selected != null) {
      return controller.boardRules
          .validateMove(
            _state.board,
            MoveAction(source: selected, target: target),
          )
          .isValid;
    }
    if (_state.laneHoldingProduct != null) {
      return controller.boardRules
          .validatePlacement(_state.board, target)
          .isValid;
    }
    return false;
  }

  String _currentBoardSyncHash() {
    return <Object?>[
      _state.board.stableHash,
      _state.selectedCell?.key,
      _state.suggestedMove?.source.key,
      _state.suggestedMove?.target.key,
      _state.laneHoldingProduct?.heldProduct?.product.id,
      _state.status.name,
    ].join('|');
  }
}

final class _ProductDragVisual {
  const _ProductDragVisual({
    required this.source,
    required this.productDef,
    required this.cellBlocker,
    required this.productBlocker,
    required this.size,
    required this.grabOffset,
    required this.position,
  });

  final CellAddress source;
  final ProductDef productDef;
  final BlockerKind cellBlocker;
  final BlockerKind productBlocker;
  final Vector2 size;
  final Vector2 grabOffset;
  final Vector2 position;

  _ProductDragVisual copyWith({required Vector2 position}) {
    return _ProductDragVisual(
      source: source,
      productDef: productDef,
      cellBlocker: cellBlocker,
      productBlocker: productBlocker,
      size: size,
      grabOffset: grabOffset,
      position: position,
    );
  }
}
