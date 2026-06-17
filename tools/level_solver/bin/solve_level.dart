import 'dart:convert';
import 'dart:io';

import 'package:shelf_rush_sort/domain/content/level_def.dart';
import 'package:shelf_rush_sort/domain/solver/bot_simulator.dart';
import 'package:shelf_rush_sort/domain/solver/validation_report.dart';

Future<void> main(List<String> args) async {
  final int levelNumber = args.isEmpty ? 1 : int.parse(args.first);
  final LevelPack pack = LevelPack.fromJson(
    jsonDecode(
          await File('assets/data/bundled/level_pack_000.json').readAsString(),
        )
        as Map<String, Object?>,
  );
  final LevelDef level = pack.levelByNumber(levelNumber);
  const BotSimulator solver = BotSimulator();
  final SolverResult result = solver.solve(level);
  stdout.writeln(
    'level=${level.id} solved=${result.solved} moves=${result.moves} reason=${result.reason ?? '-'}',
  );
  if (!result.solved) {
    exitCode = 1;
  }
}
