import 'package:flame/game.dart';

import '../../../domain/core/value_objects.dart';
import 'input_router.dart';

final class DragController {
  const DragController(this.inputRouter);

  final InputRouter inputRouter;

  void start(CellAddress address) {
    inputRouter.onProductDragStart(address);
  }

  void end(Vector2 canvasPosition) {
    inputRouter.onProductDragEnd(canvasPosition);
  }
}
