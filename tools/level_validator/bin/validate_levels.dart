import 'dart:convert';
import 'dart:io';

import 'package:shelf_rush_sort/domain/content/level_def.dart';
import 'package:shelf_rush_sort/domain/content/product_def.dart';
import 'package:shelf_rush_sort/domain/solver/solver.dart';
import 'package:shelf_rush_sort/domain/solver/validation_report.dart';

Future<void> main() async {
  final ProductCatalog catalog = ProductCatalog.fromJson(
    await _readJson('assets/data/bundled/product_catalog.json'),
  );
  final LevelPack pack = LevelPack.fromJson(
    await _readJson('assets/data/bundled/level_pack_000.json'),
  );
  const LevelValidator validator = LevelValidator();
  final ValidationReport report = validator.validatePack(pack, catalog);
  if (report.passed) {
    stdout.writeln('Validated ${pack.levels.length} levels.');
    return;
  }
  for (final ValidationIssue issue in report.issues) {
    stderr.writeln(
      '${issue.levelId ?? 'pack'} ${issue.code}: ${issue.message}',
    );
  }
  exitCode = 1;
}

Future<Map<String, Object?>> _readJson(String path) async {
  final String raw = await File(path).readAsString();
  return jsonDecode(raw) as Map<String, Object?>;
}
