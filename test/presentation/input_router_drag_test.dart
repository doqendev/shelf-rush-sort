import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/application/game_session/game_session_controller.dart';
import 'package:shelf_rush_sort/domain/content/level_def.dart';
import 'package:shelf_rush_sort/domain/core/value_objects.dart';
import 'package:shelf_rush_sort/domain/game/objective.dart';
import 'package:shelf_rush_sort/infrastructure/analytics/analytics_service.dart';
import 'package:shelf_rush_sort/presentation/flame/board/board_layout_calculator.dart';
import 'package:shelf_rush_sort/presentation/flame/input/input_router.dart';

void main() {
  test('product drag lifecycle updates preview hooks and drops on target', () {
    final GameSessionController controller = GameSessionController(
      level: _level(),
      analytics: DebugAnalyticsService(),
    );
    final layout = const BoardLayoutCalculator().calculate(
      Vector2(390, 844),
      hasLane: false,
    );
    final List<Vector2> updates = <Vector2>[];
    CellAddress? startedAddress;
    Vector2? startedPosition;
    var finishedCount = 0;
    final InputRouter router = InputRouter(
      controller: controller,
      layout: layout,
      onProductDragStarted: (CellAddress address, Vector2 canvasPosition) {
        startedAddress = address;
        startedPosition = canvasPosition;
      },
      onProductDragUpdated: updates.add,
      onProductDragFinished: () {
        finishedCount += 1;
      },
    );
    final CellAddress source = CellAddress.fromCompartmentIndex(1, 0);
    final CellAddress target = CellAddress.fromCompartmentIndex(0, 2);
    final targetCenter = layout.cellRect(target).center;

    router.onProductDragStart(source, Vector2(140, 320));
    router.onProductDragUpdate(Vector2(155, 300));
    router.onProductDragEnd(Vector2(targetCenter.dx, targetCenter.dy));

    expect(startedAddress, source);
    expect(startedPosition, Vector2(140, 320));
    expect(updates, <Vector2>[Vector2(155, 300)]);
    expect(finishedCount, 1);
    expect(controller.state.moveCount, 1);
    expect(controller.state.board.visibleProductCount, 0);
  });
}

LevelDef _level() {
  return LevelDef(
    id: 'input_router_drag_test',
    levelNumber: 10,
    title: 'Input Router Drag Test',
    seed: 10,
    objective: ObjectiveRequirement(type: ObjectiveType.clearAll),
    compartments: <CompartmentDef>[
      CompartmentDef(
        index: 0,
        cells: const <String?>['sku_000', 'sku_000', null],
      ),
      CompartmentDef(index: 1, cells: const <String?>['sku_000', null, null]),
      for (var index = 2; index < compartmentCount; index += 1)
        CompartmentDef(
          index: index,
          locked: true,
          cells: const <String?>[null, null, null],
        ),
    ],
  );
}
