import 'dart:ui';

import 'package:flame/game.dart';

import '../../../domain/core/value_objects.dart';
import '../../../domain/game/board_rules.dart';
import '../../../domain/game/board_state.dart';
import '../board/board_layout_calculator.dart';

final class MagnetTargeting {
  const MagnetTargeting({this.boardRules = const BoardRules()});

  final BoardRules boardRules;

  CellAddress? targetFor(
    BoardLayout layout,
    Vector2 canvasPosition, {
    BoardState? board,
    ProductInstance? movingProduct,
    double magnetRadiusPx = 54,
  }) {
    final CellAddress? direct = layout.hitTestCell(canvasPosition);
    if (_isLegalTarget(board, movingProduct, direct)) {
      return direct;
    }
    CellAddress? nearest;
    var nearestDistance = magnetRadiusPx * magnetRadiusPx;
    for (final MapEntry<CellAddress, Rect> entry
        in layout.hitCellRects.entries) {
      if (!_isLegalTarget(board, movingProduct, entry.key)) {
        continue;
      }
      final Vector2 center = Vector2(
        layout.cellRect(entry.key).center.dx,
        layout.cellRect(entry.key).center.dy,
      );
      final double distance = center.distanceToSquared(canvasPosition);
      if (distance <= nearestDistance) {
        nearest = entry.key;
        nearestDistance = distance;
      }
    }
    return nearest;
  }

  bool _isLegalTarget(
    BoardState? board,
    ProductInstance? movingProduct,
    CellAddress? target,
  ) {
    if (target == null || board == null || movingProduct == null) {
      return target != null;
    }
    return boardRules
        .placeProduct(board, product: movingProduct, target: target)
        .isValid;
  }
}
