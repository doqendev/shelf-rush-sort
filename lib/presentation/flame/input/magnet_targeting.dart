import 'package:flame/game.dart';

import '../../../domain/core/value_objects.dart';
import '../board/board_layout_calculator.dart';

final class MagnetTargeting {
  const MagnetTargeting();

  CellAddress? targetFor(BoardLayout layout, Vector2 canvasPosition) {
    return layout.hitTestCell(canvasPosition);
  }
}
