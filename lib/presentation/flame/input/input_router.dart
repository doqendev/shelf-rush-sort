import 'package:flame/game.dart';

import '../../../application/game_session/game_session_controller.dart';
import '../../../domain/core/value_objects.dart';
import '../../../domain/game/board_state.dart';
import '../board/board_layout_calculator.dart';
import 'magnet_targeting.dart';

final class InputRouter {
  InputRouter({
    required this.controller,
    required BoardLayout layout,
    this.magnetTargeting = const MagnetTargeting(),
    this.onProductDragStarted,
    this.onProductDragUpdated,
    this.onProductDragFinished,
  }) : _layout = layout;

  final GameSessionController controller;
  final MagnetTargeting magnetTargeting;
  void Function(CellAddress address, Vector2 canvasPosition)?
  onProductDragStarted;
  void Function(Vector2 canvasPosition)? onProductDragUpdated;
  void Function(CellAddress? target)? onProductDragFinished;
  BoardLayout _layout;

  set layout(BoardLayout layout) {
    _layout = layout;
  }

  void onProductTapped(CellAddress address) {
    controller.selectCell(address);
  }

  void onCellTapped(CellAddress address) {
    controller.placeSelectedAt(address);
  }

  void onProductDragStart(CellAddress address, Vector2 canvasPosition) {
    onProductDragStarted?.call(address, canvasPosition);
    controller.selectCell(address);
  }

  void onProductDragUpdate(Vector2 canvasPosition) {
    onProductDragUpdated?.call(canvasPosition);
  }

  void onProductDragEnd(Vector2 canvasPosition) {
    final CellAddress? selected = controller.state.selectedCell;
    final ProductInstance? movingProduct = selected == null
        ? null
        : controller.state.board.productAt(selected);
    final CellAddress? target = magnetTargeting.targetFor(
      _layout,
      canvasPosition,
      board: controller.state.board,
      movingProduct: movingProduct,
    );
    // The presentation layer commits the move after the snap animation lands
    // (ShelfWorld._finishProductDragVisual), so the lifted product visibly
    // springs into the shelf instead of teleporting to it.
    onProductDragFinished?.call(target);
  }

  void onLaneProductTapped(String laneId) {
    controller.grabLaneProduct(laneId);
  }

  void onLaneProductDragStart(String laneId) {
    controller.grabLaneProduct(laneId);
  }

  void onLaneProductDragEnd(Vector2 canvasPosition) {
    final ProductInstance? movingProduct =
        controller.state.laneHoldingProduct?.heldProduct?.product;
    final CellAddress? target = magnetTargeting.targetFor(
      _layout,
      canvasPosition,
      board: controller.state.board,
      movingProduct: movingProduct,
    );
    if (target != null) {
      controller.placeHeldLaneProduct(target);
    }
  }
}
