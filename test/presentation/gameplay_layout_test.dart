import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/application/game_session/game_session_state.dart';
import 'package:shelf_rush_sort/domain/content/level_def.dart';
import 'package:shelf_rush_sort/domain/core/value_objects.dart';
import 'package:shelf_rush_sort/domain/game/board_rules.dart';
import 'package:shelf_rush_sort/domain/game/objective.dart';
import 'package:shelf_rush_sort/domain/game/replay.dart';
import 'package:shelf_rush_sort/domain/game/timer.dart';
import 'package:shelf_rush_sort/presentation/widgets/gameplay/game_scaffold.dart';

void main() {
  for (final Size size in const <Size>[
    Size(320, 568),
    Size(360, 640),
    Size(390, 844),
    Size(430, 932),
  ]) {
    testWidgets('gameplay scaffold fits ${size.width.toInt()} px viewport', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScaffold(
            session: _session(),
            onPause: () {},
            viewport: const ColoredBox(color: Color(0xFF00AAFF)),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Pause'), findsOneWidget);
      expect(tester.getSize(find.byTooltip('Pause')), const Size(44, 44));
      expect(find.text('Level 1'), findsOneWidget);
      // Mechanic-specific objective copy + a live "N left" progress count.
      expect(find.textContaining('matching'), findsOneWidget);
      expect(find.textContaining('left'), findsOneWidget);
      expect(find.byIcon(Icons.map_rounded), findsNothing);
      expect(find.byIcon(Icons.storefront), findsNothing);
      expect(find.byIcon(Icons.settings), findsNothing);
      expect(find.byIcon(Icons.analytics_outlined), findsNothing);
      expect(find.text('500'), findsNothing);
    });
  }
}

GameSessionState _session() {
  final LevelDef level = LevelDef(
    id: 'layout_test',
    levelNumber: 1,
    title: 'Layout Test',
    seed: 1,
    objective: ObjectiveRequirement(type: ObjectiveType.clearAll),
    compartments: <CompartmentDef>[
      CompartmentDef(
        index: 0,
        cells: const <String?>['sku_000', 'sku_000', null],
      ),
      CompartmentDef(index: 1, cells: const <String?>['sku_000', null, null]),
      for (var index = 2; index < compartmentCount; index += 1)
        CompartmentDef(index: index, cells: const <String?>[null, null, null]),
    ],
  );
  final board = const BoardRules().resolveBoard(level.createBoardState()).state;
  return GameSessionState(
    level: level,
    board: board,
    objective: const ObjectiveRules().initialState(
      requirement: level.objective,
      board: board,
    ),
    timer: LevelTimer.fromSeconds(level.timeLimitSeconds),
    replay: ReplayLog(levelId: level.id, seed: level.seed),
    lanes: const [],
    attemptId: 'layout_attempt',
  );
}
