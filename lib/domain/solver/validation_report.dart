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

final class ValidationReport {
  ValidationReport({List<ValidationIssue> issues = const <ValidationIssue>[]})
    : issues = List<ValidationIssue>.unmodifiable(issues);

  final List<ValidationIssue> issues;

  bool get passed => issues.isEmpty;
}

final class SolverResult {
  const SolverResult({required this.solved, required this.moves, this.reason});

  final bool solved;
  final int moves;
  final String? reason;
}
