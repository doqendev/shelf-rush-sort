final class ValidationIssue {
  const ValidationIssue({
    required this.code,
    required this.message,
    this.levelId,
  });

  final String code;
  final String message;
  final String? levelId;
}

final class LevelValidationMetrics {
  LevelValidationMetrics({
    required this.solvable,
    required this.minSolutionMoves,
    required this.botWinRate,
    required this.deadEndProbability,
    required this.averageUsefulMoveRatio,
    required this.activeCompartmentCount,
    required this.occupiedFrontCellCount,
    required this.emptyFrontRatio,
    required this.lockedCompartmentRatio,
    required this.duplicatePatternRatio,
    required this.uniqueSkuCount,
    required this.hiddenProductCount,
    required this.hiddenAutoClearRisk,
    required this.laneCount,
    required this.laneDependencyRatio,
    required this.laneMissFailureRisk,
    required this.densityGrade,
    required this.difficultyGrade,
    List<String> riskFlags = const <String>[],
  }) : riskFlags = List<String>.unmodifiable(riskFlags);

  final bool solvable;
  final int minSolutionMoves;
  final double botWinRate;
  final double deadEndProbability;
  final double averageUsefulMoveRatio;
  final int activeCompartmentCount;
  final int occupiedFrontCellCount;
  final double emptyFrontRatio;
  final double lockedCompartmentRatio;
  final double duplicatePatternRatio;
  final int uniqueSkuCount;
  final int hiddenProductCount;
  final double hiddenAutoClearRisk;
  final int laneCount;
  final double laneDependencyRatio;
  final double laneMissFailureRisk;
  final String densityGrade;
  final String difficultyGrade;
  final List<String> riskFlags;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'solvable': solvable,
      'minSolutionMoves': minSolutionMoves,
      'botWinRate': botWinRate,
      'deadEndProbability': deadEndProbability,
      'averageUsefulMoveRatio': averageUsefulMoveRatio,
      'activeCompartmentCount': activeCompartmentCount,
      'occupiedFrontCellCount': occupiedFrontCellCount,
      'emptyFrontRatio': emptyFrontRatio,
      'lockedCompartmentRatio': lockedCompartmentRatio,
      'duplicatePatternRatio': duplicatePatternRatio,
      'uniqueSkuCount': uniqueSkuCount,
      'hiddenProductCount': hiddenProductCount,
      'hiddenAutoClearRisk': hiddenAutoClearRisk,
      'laneCount': laneCount,
      'laneDependencyRatio': laneDependencyRatio,
      'laneMissFailureRisk': laneMissFailureRisk,
      'densityGrade': densityGrade,
      'difficultyGrade': difficultyGrade,
      'riskFlags': riskFlags,
    };
  }
}

final class ValidationReport {
  ValidationReport({
    List<ValidationIssue> issues = const <ValidationIssue>[],
    Map<String, LevelValidationMetrics> metricsByLevel =
        const <String, LevelValidationMetrics>{},
  }) : issues = List<ValidationIssue>.unmodifiable(issues),
       metricsByLevel = Map<String, LevelValidationMetrics>.unmodifiable(
         metricsByLevel,
       );

  final List<ValidationIssue> issues;
  final Map<String, LevelValidationMetrics> metricsByLevel;

  bool get passed => issues.isEmpty;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'passed': passed,
      'issues': issues
          .map((ValidationIssue issue) {
            return <String, Object?>{
              'levelId': issue.levelId,
              'code': issue.code,
              'message': issue.message,
            };
          })
          .toList(growable: false),
      'metricsByLevel': <String, Object?>{
        for (final MapEntry<String, LevelValidationMetrics> entry
            in metricsByLevel.entries)
          entry.key: entry.value.toJson(),
      },
    };
  }
}

final class SolverResult {
  const SolverResult({required this.solved, required this.moves, this.reason});

  final bool solved;
  final int moves;
  final String? reason;
}
