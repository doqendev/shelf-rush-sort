import 'package:flame/game.dart';

import '../../../application/game_session/game_session_controller.dart';
import '../../../domain/core/value_objects.dart';
import '../board/board_layout_calculator.dart';
import 'magnet_targeting.dart';

final class InputRouter {
  InputRouter({
    required this.controller,
    required BoardLayout layout,
    this.magnetTargeting = const MagnetTargeting(),
  }) : _layout = layout;

  final GameSessionController controller;
  final MagnetTargeting magnetTargeting;
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

  void onProductDragStart(CellAddress address) {
    controller.selectCell(address);
  }

  void onProductDragEnd(Vector2 canvasPosition) {
    final CellAddress? target = magnetTargeting.targetFor(
      _layout,
      canvasPosition,
    );
    if (target != null) {
      controller.placeSelectedAt(target);
    }
  }

  void onLaneProductTapped(String laneId) {
    controller.grabLaneProduct(laneId);
  }
}
