import '../../domain/boosters/booster_def.dart';
import '../../domain/core/value_objects.dart';

sealed class GameCommand {
  const GameCommand();
}

final class SelectCellCommand extends GameCommand {
  const SelectCellCommand(this.address);

  final CellAddress address;
}

final class PlaceSelectedCommand extends GameCommand {
  const PlaceSelectedCommand(this.target);

  final CellAddress target;
}

final class GrabLaneProductCommand extends GameCommand {
  const GrabLaneProductCommand(this.laneId);

  final String laneId;
}

final class PlaceHeldLaneProductCommand extends GameCommand {
  const PlaceHeldLaneProductCommand(this.target);

  final CellAddress target;
}

final class UseBoosterCommand extends GameCommand {
  const UseBoosterCommand(this.booster);

  final BoosterKind booster;
}
