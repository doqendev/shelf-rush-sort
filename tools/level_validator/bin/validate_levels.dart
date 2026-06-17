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
  await _writeReports(report);
  if (report.passed) {
    stdout.writeln('Validated ${pack.levels.length} levels.');
    stdout.writeln('Wrote build/reports/validation_report.json.');
    stdout.writeln('Wrote build/reports/difficulty_dashboard.csv.');
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

Future<void> _writeReports(ValidationReport report) async {
  final Directory output = Directory('build/reports');
  await output.create(recursive: true);
  await File(
    '${output.path}/validation_report.json',
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(report.toJson()));
  final StringBuffer csv = StringBuffer()
    ..writeln(
      'level_id,solvable,min_solution_moves,bot_win_rate,dead_end_probability,average_useful_move_ratio,active_compartment_count,occupied_front_cell_count,empty_front_ratio,locked_compartment_ratio,duplicate_pattern_ratio,unique_sku_count,hidden_product_count,hidden_auto_clear_risk,lane_count,lane_dependency_ratio,lane_miss_failure_risk,density_grade,difficulty_grade,risk_flags',
    );
  for (final MapEntry<String, LevelValidationMetrics> entry
      in report.metricsByLevel.entries) {
    final LevelValidationMetrics metrics = entry.value;
    csv.writeln(
      <Object?>[
        entry.key,
        metrics.solvable,
        metrics.minSolutionMoves,
        metrics.botWinRate,
        metrics.deadEndProbability,
        metrics.averageUsefulMoveRatio,
        metrics.activeCompartmentCount,
        metrics.occupiedFrontCellCount,
        metrics.emptyFrontRatio,
        metrics.lockedCompartmentRatio,
        metrics.duplicatePatternRatio,
        metrics.uniqueSkuCount,
        metrics.hiddenProductCount,
        metrics.hiddenAutoClearRisk,
        metrics.laneCount,
        metrics.laneDependencyRatio,
        metrics.laneMissFailureRisk,
        metrics.densityGrade,
        metrics.difficultyGrade,
        metrics.riskFlags.join('|'),
      ].map(_csvCell).join(','),
    );
  }
  await File(
    '${output.path}/difficulty_dashboard.csv',
  ).writeAsString(csv.toString());
}

String _csvCell(Object? value) {
  final String text = '$value';
  if (!text.contains(',') && !text.contains('"') && !text.contains('\n')) {
    return text;
  }
  return '"${text.replaceAll('"', '""')}"';
}
