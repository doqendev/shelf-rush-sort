import 'dart:io';

Future<void> main() async {
  final List<String> failures = <String>[
    ...await _checkDomainPurity(),
    ...await _checkPresentationDoesNotParseJson(),
    ...await _checkNoProductionPrints(),
  ];
  if (failures.isEmpty) {
    stdout.writeln('Architecture checks passed.');
    return;
  }
  for (final String failure in failures) {
    stderr.writeln(failure);
  }
  exitCode = 1;
}

Future<List<String>> _checkDomainPurity() async {
  final List<String> failures = <String>[];
  await for (final File file in _dartFiles('lib/domain')) {
    final String source = await file.readAsString();
    for (final String forbidden in <String>[
      'package:flutter',
      'package:flame',
      'dart:ui',
      'BuildContext',
      'Widget',
    ]) {
      if (source.contains(forbidden)) {
        failures.add(
          '${file.path}: domain code must not reference $forbidden.',
        );
      }
    }
  }
  return failures;
}

Future<List<String>> _checkPresentationDoesNotParseJson() async {
  final List<String> failures = <String>[];
  await for (final File file in _dartFiles('lib/presentation')) {
    final String source = await file.readAsString();
    if (source.contains('jsonDecode') || source.contains('dart:convert')) {
      failures.add(
        '${file.path}: presentation code must not parse content JSON.',
      );
    }
  }
  return failures;
}

Future<List<String>> _checkNoProductionPrints() async {
  final List<String> failures = <String>[];
  await for (final File file in _dartFiles('lib')) {
    final String source = await file.readAsString();
    if (source.contains('print(') || source.contains('debugPrint(')) {
      failures.add('${file.path}: production code must not print directly.');
    }
  }
  return failures;
}

Stream<File> _dartFiles(String rootPath) async* {
  final Directory root = Directory(rootPath);
  if (!await root.exists()) {
    return;
  }
  await for (final FileSystemEntity entity in root.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      yield entity;
    }
  }
}
