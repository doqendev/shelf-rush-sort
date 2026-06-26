import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import '../../application/game_session/game_session_controller.dart';
import '../../application/game_session/game_session_state.dart';
import '../../application/game_session/tutorial_controller.dart';
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
import 'board/compartment_component.dart';
import 'board/cozy_sprite_cache.dart';
import 'board/dragged_product_component.dart';
import 'board/hidden_preview_component.dart';
import 'board/hover_target_component.dart';
import 'board/product_component.dart';
import 'board/rack_backdrop_component.dart';
import 'board/tutorial_overlay_component.dart';
import 'fx/clear_pop_component.dart';
import 'fx/fx_director.dart';
import 'fx/product_pop_component.dart';
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
  HoverTargetComponent? _hoverComponent;

  /// Retained product components, keyed by stable [ProductInstance.id]. A moved
  /// product keeps its component (and animates) rather than being rebuilt in
  /// place (second-pass audit M2).
  final Map<ProductInstanceId, ProductComponent> _productComponents =
      <ProductInstanceId, ProductComponent>{};

  /// Gates the product drop-in entrance: skip the very first build, and skip
  /// products that just arrived via a drag snap (they already animated).
  bool _hasReconciledOnce = false;
  final Set<ProductInstanceId> _suppressEntrance = <ProductInstanceId>{};

  /// When a clear fires in the same beat as a hidden reveal, the revealed
  /// products wait this long (≈ the clear-pop duration) before fading in, so a
  /// reveal lands after the pop instead of overlapping it (Sprint C / P1.1).
  static const double _revealAfterClearDelay = 0.30;
  double _pendingRevealDelay = 0;
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
    // Re-layout snaps products to their new slots (a resize is not a "move").
    unawaited(rebuild(animateMoves: false));
  }

  void syncState(GameSessionState state) {
    final String previousBoardHash = _boardSyncHash;
    _state = state;
    // A hidden reveal landing in the same beat as a clear waits for the pop to
    // finish before fading in (hands-on P1.1 / Sprint C presentation order).
    final bool clearedThisBeat = state.events.any(
      (SessionEvent event) => event.type == SessionEventType.tripleCleared,
    );
    _pendingRevealDelay = clearedThisBeat ? _revealAfterClearDelay : 0;
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

  Future<void> rebuild({bool animateMoves = true}) async {
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
                  child != _productDragComponent &&
                  child != _hoverComponent &&
                  child is! ProductComponent &&
                  child is! ClearPopComponent &&
                  child is! ProductPopComponent,
            )
            .toList(),
      );
      _laneComponents.clear();
      await _addBoard();
      await _addLanes();
      await _syncProductDragComponent();
      await _reconcileProducts(animate: animateMoves);
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
      if (!compartment.interactable) {
        // Locked/decorative compartments are inactive: draw a clearly covered
        // shelf and add no interactive target cells, so they can't be mistaken
        // for valid empty slots (second-pass audit P0.5).
        await add(
          CompartmentComponent(
            locked: compartment.locked,
            decorative: compartment.decorative,
            position: Vector2(compartmentRect.left, compartmentRect.top),
            size: Vector2(compartmentRect.width, compartmentRect.height),
          ),
        );
        continue;
      }
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
        final ShelfCell shelfCell = compartment.cellAt(cell);
        // Products are retained components managed by _reconcileProducts; the
        // scaffold only lays down interactive targets for the empty slots.
        if (shelfCell.product != null) {
          continue;
        }
        final Rect cellRect = _layout.cellRect(address);
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
      }
    }
    await _addTutorialOverlay();
  }

  /// Reconciles the retained product components against the current board.
  /// Because [ProductInstance.id] is stable, a product that changed slots
  /// (booster shuffle, settle) keeps its component and animates to the new slot
  /// instead of teleporting (second-pass audit M2). Products that are gone
  /// (cleared, or lifted by a drag) are removed — their exit is shown by the
  /// clear FX / the dragged visual.
  Future<void> _reconcileProducts({required bool animate}) async {
    final Map<ProductInstanceId, _ProductPlacement> desired =
        <ProductInstanceId, _ProductPlacement>{};
    for (final CompartmentState compartment in _state.board.compartments) {
      if (!compartment.interactable) {
        continue;
      }
      for (var cell = 0; cell < cellsPerCompartment; cell += 1) {
        final CellAddress address = compartment.addressForCell(cell);
        final ShelfCell shelfCell = compartment.cellAt(cell);
        final ProductInstance? product = shelfCell.product;
        if (product == null || _productDragVisual?.source == address) {
          continue;
        }
        final ProductDef? productDef = productCatalog.bySku(product.skuId);
        if (productDef == null) {
          continue;
        }
        final Rect rect = _layout.cellRect(address);
        desired[product.id] = _ProductPlacement(
          address: address,
          productDef: productDef,
          selected: _state.selectedCell == address,
          cellBlocker: shelfCell.blocker,
          productBlocker: product.blocker,
          position: Vector2(rect.left, rect.top),
          size: Vector2(rect.width, rect.height),
        );
      }
    }

    final List<ProductInstanceId> gone = <ProductInstanceId>[
      for (final ProductInstanceId id in _productComponents.keys)
        if (!desired.containsKey(id)) id,
    ];
    for (final ProductInstanceId id in gone) {
      _productComponents.remove(id)?.removeFromParent();
    }

    for (final MapEntry<ProductInstanceId, _ProductPlacement> entry
        in desired.entries) {
      final _ProductPlacement placement = entry.value;
      final ProductComponent? existing = _productComponents[entry.key];
      if (existing == null || !existing.isMounted) {
        // A not-yet-mounted component for this id is about to be replaced in
        // the map; remove it first so it cannot later mount as an orphan that
        // `gone` (which only scans the map) would never collect. Surfaces when
        // a hidden reveal re-syncs the board before the first component mounts.
        existing?.removeFromParent();
        final ProductComponent created = ProductComponent(
          address: placement.address,
          productDef: placement.productDef,
          inputRouter: inputRouter,
          selected: placement.selected,
          cellBlocker: placement.cellBlocker,
          productBlocker: placement.productBlocker,
          position: placement.position.clone(),
          size: placement.size,
        );
        _productComponents[entry.key] = created;
        await add(created);
        // Drop newly-appeared products (hidden reveals, lane placements) into
        // their slot rather than popping in. Skip the first build and products
        // that just arrived via a drag snap (audit M2 / section 7).
        final bool suppressed = _suppressEntrance.remove(entry.key);
        if (_hasReconciledOnce && animate && !reduceMotion && !suppressed) {
          final double revealDelay = _pendingRevealDelay;
          created.position = placement.position - Vector2(0, 16);
          // A reveal arriving with a clear stays invisible until the pop
          // finishes, then fades + drops into the freed slot (Sprint C).
          if (revealDelay > 0) {
            created.playRevealEntrance(revealDelay);
          }
          created.add(
            MoveToEffect(
              placement.position.clone(),
              EffectController(
                duration: 0.2,
                startDelay: revealDelay,
                curve: Curves.easeOutBack,
              ),
            ),
          );
        }
        continue;
      }
      existing
        ..address = placement.address
        ..selected = placement.selected
        ..cellBlocker = placement.cellBlocker
        ..productBlocker = placement.productBlocker
        ..size = placement.size;
      // Cancel any in-flight relocation before deciding the next one.
      existing.children.whereType<MoveToEffect>().toList().forEach(
        (MoveToEffect effect) => effect.removeFromParent(),
      );
      final Vector2 target = placement.position;
      if (!animate || existing.position.distanceTo(target) < 0.5) {
        existing.position = target.clone();
        continue;
      }
      existing.add(
        MoveToEffect(
          target.clone(),
          EffectController(duration: 0.26, curve: Curves.easeOutCubic),
        ),
      );
    }
    _hasReconciledOnce = true;
  }

  /// Adds the guided-move overlay while the opening tutorial step is active
  /// (level 1, before the first move). It is recreated each rebuild and simply
  /// not re-added once the first move is made (second-pass audit P0.5).
  Future<void> _addTutorialOverlay() async {
    final TutorialMoveHint? hint = controller.tutorialController.hintForLevel(
      _state.level.levelNumber,
    );
    if (hint == null || _state.moveCount != 0 || _state.isEnded) {
      return;
    }
    await add(
      TutorialOverlayComponent(
        sourceRect: _layout.cellRect(hint.source),
        targetRect: _layout.cellRect(hint.target),
        message: 'Drag matching products together',
        size: _layout.gameSize,
        reduceMotion: reduceMotion,
      ),
    );
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
    _updateHoverTarget(canvasPosition);
  }

  /// Strongly emphasises the slot the dragged product is aimed at — gold (with
  /// a "3" badge) when the drop completes a triple, otherwise green — so the
  /// outcome is visible before release (second-pass audit P1.2).
  void _updateHoverTarget(Vector2 canvasPosition) {
    final CellAddress? source = _productDragVisual?.source;
    if (source == null) {
      _clearHoverTarget();
      return;
    }
    final ProductInstance? moving = _state.board.productAt(source);
    final CellAddress? target = inputRouter.magnetTargeting.targetFor(
      _layout,
      canvasPosition,
      board: _state.board,
      movingProduct: moving,
    );
    if (target == null || target == source) {
      _clearHoverTarget();
      return;
    }
    final MoveQuality quality = controller.boardRules.classifyMove(
      _state.board,
      MoveAction(source: source, target: target),
    );
    final Rect rect = _layout.cellRect(target);
    final HoverTargetComponent? existing = _hoverComponent;
    if (existing != null && existing.isMounted) {
      existing.position = Vector2(rect.left, rect.top);
      existing.size = Vector2(rect.width, rect.height);
      existing.quality = quality;
      return;
    }
    final HoverTargetComponent created = HoverTargetComponent(
      quality: quality,
      position: Vector2(rect.left, rect.top),
      size: Vector2(rect.width, rect.height),
    );
    _hoverComponent = created;
    final FutureOr<void> pending = add(created);
    if (pending is Future<void>) {
      unawaited(pending);
    }
  }

  void _clearHoverTarget() {
    _hoverComponent?.removeFromParent();
    _hoverComponent = null;
  }

  void _finishProductDragVisual(CellAddress? target) {
    _clearHoverTarget();
    final _ProductDragVisual? visual = _productDragVisual;
    final DraggedProductComponent? component = _productDragComponent;
    // No drag visual, or reduced motion: commit immediately and settle.
    if (component == null || visual == null || reduceMotion) {
      _productDragVisual = null;
      _productDragComponent = null;
      if (target != null) {
        controller.placeSelectedAt(target);
      } else {
        controller.cancelSelection();
      }
      component?.removeFromParent();
      unawaited(rebuild());
      return;
    }
    _productDragVisual = null;
    if (target == null) {
      // Invalid drop: spring the lifted product back to its source shelf
      // (P1.2 — a cancelled drag animates home, it does not snap back instantly).
      final Rect source = _layout.cellRect(visual.source);
      component.animateTo(
        Vector2(source.left, source.top),
        onComplete: () {
          _productDragComponent = null;
          controller.cancelSelection();
          component.removeFromParent();
          unawaited(rebuild());
        },
      );
      return;
    }
    // Valid drop: spring the product into the destination slot, THEN commit the
    // move, so it visibly settles before the board resolves (review section 10).
    final Rect destination = _layout.cellRect(target);
    final ProductInstance? placed = _state.board.productAt(visual.source);
    component.animateTo(
      Vector2(destination.left, destination.top),
      onComplete: () {
        _productDragComponent = null;
        // The product already sprang into the slot — don't also drop it in.
        if (placed != null) {
          _suppressEntrance.add(placed.id);
        }
        controller.placeSelectedAt(target);
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
  void playTripleClearFx(int compartmentIndex, int comboIndex, String skuId) {
    final Rect rect = _layout.compartmentRect(compartmentIndex);
    _spawnFx(
      ClearPopComponent(
        position: Vector2(rect.left, rect.top),
        size: Vector2(rect.width, rect.height),
        comboIndex: comboIndex,
      ),
    );
    // Squash/pop each cleared product out of its slot (staggered) so the match
    // resolves as objects, not an instant board swap (second-pass audit M2).
    final Image? sprite = CozySpriteCache.instance.imageForSku(skuId);
    for (var cell = 0; cell < cellsPerCompartment; cell += 1) {
      final Rect cellRect = _layout.cellRect(
        CellAddress.fromCompartmentIndex(compartmentIndex, cell),
      );
      _spawnFx(
        ProductPopComponent(
          image: sprite,
          position: Vector2(cellRect.left, cellRect.top),
          size: Vector2(cellRect.width, cellRect.height),
          delay: cell * 0.04,
        ),
      );
    }
  }

  void _spawnFx(Component component) {
    final FutureOr<void> pending = add(component);
    if (pending is Future<void>) {
      unawaited(pending);
    }
  }

  /// Whether the board is still animating its end-of-level celebration — active
  /// clear/pop FX or in-flight product move tweens. The win/loss overlay waits
  /// for this to settle so the final beat is seen first (audit M2 / section 7).
  bool get isPresentationBusy {
    for (final Component child in children) {
      if (child is ClearPopComponent || child is ProductPopComponent) {
        return true;
      }
      if (child is ProductComponent &&
          (child.isRevealing ||
              child.children.whereType<MoveToEffect>().isNotEmpty)) {
        return true;
      }
    }
    return false;
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

/// The desired on-screen placement for one product during reconciliation.
final class _ProductPlacement {
  const _ProductPlacement({
    required this.address,
    required this.productDef,
    required this.selected,
    required this.cellBlocker,
    required this.productBlocker,
    required this.position,
    required this.size,
  });

  final CellAddress address;
  final ProductDef productDef;
  final bool selected;
  final BlockerKind cellBlocker;
  final BlockerKind productBlocker;
  final Vector2 position;
  final Vector2 size;
}
