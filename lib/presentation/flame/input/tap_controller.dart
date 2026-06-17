import '../../../domain/core/value_objects.dart';
import 'input_router.dart';

final class TapController {
  const TapController(this.inputRouter);

  final InputRouter inputRouter;

  void tapCell(CellAddress address) {
    inputRouter.onCellTapped(address);
  }
}
