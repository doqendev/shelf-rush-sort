import 'dart:convert';
import 'dart:io';

const int _mib = 1024 * 1024;

const Map<String, _Budget> _fileBudgets = <String, _Budget>{
  'build/app/outputs/flutter-apk/app-debug.apk': _Budget(
    label: 'debug APK',
    maxBytes: 190 * _mib,
  ),
  'build/web/main.dart.js': _Budget(
    label: 'web main.dart.js',
    maxBytes: 4 * _mib,
  ),
  'assets/data/bundled/level_pack_000.json': _Budget(
    label: 'bundled level pack',
    maxBytes: 2 * _mib,
  ),
  'assets/data/bundled/asset_manifest.json': _Budget(
    label: 'product visual manifest',
    maxBytes: 256 * 1024,
  ),
};

const Map<String, _Budget> _directoryBudgets = <String, _Budget>{
  'build/web': _Budget(label: 'web build directory', maxBytes: 40 * _mib),
};

const List<String> _requiredPerformanceEvents = <String>[
  'performance_level_load',
  'performance_frame_bucket',
  'memory_warning',
  'asset_load_failure',
];

Future<void> main() async {
  final List<String> failures = <String>[];

  for (final MapEntry<String, _Budget> entry in _fileBudgets.entries) {
    final File file = File(entry.key);
    if (!file.existsSync()) {
      failures.add('Missing ${entry.value.label}: ${entry.key}');
      continue;
    }
    _checkBudget(entry.value, file.lengthSync(), failures);
  }

  for (final MapEntry<String, _Budget> entry in _directoryBudgets.entries) {
    final Directory directory = Directory(entry.key);
    if (!directory.existsSync()) {
      failures.add('Missing ${entry.value.label}: ${entry.key}');
      continue;
    }
    _checkBudget(entry.value, _directorySize(directory), failures);
  }

  await _checkPerformanceEvents(failures);

  if (failures.isEmpty) {
    stdout.writeln('Release audit passed.');
    return;
  }

  for (final String failure in failures) {
    stderr.writeln(failure);
  }
  exitCode = 1;
}

Future<void> _checkPerformanceEvents(List<String> failures) async {
  final File eventCatalog = File('assets/data/bundled/event_catalog.json');
  if (!eventCatalog.existsSync()) {
    failures.add('Missing event catalog: ${eventCatalog.path}');
    return;
  }
  final Map<String, Object?> json =
      jsonDecode(await eventCatalog.readAsString()) as Map<String, Object?>;
  final List<Object?> events = json['events']! as List<Object?>;
  final Set<String> eventNames = <String>{
    for (final Object? event in events)
      if (event is Map<String, Object?> && event['name'] is String)
        event['name']! as String,
  };
  for (final String requiredEvent in _requiredPerformanceEvents) {
    if (!eventNames.contains(requiredEvent)) {
      failures.add('Missing performance analytics event: $requiredEvent');
    }
  }
}

void _checkBudget(_Budget budget, int actualBytes, List<String> failures) {
  stdout.writeln(
    '${budget.label}: ${_formatBytes(actualBytes)} / '
    '${_formatBytes(budget.maxBytes)}',
  );
  if (actualBytes > budget.maxBytes) {
    failures.add(
      '${budget.label} exceeds budget: '
      '${_formatBytes(actualBytes)} > ${_formatBytes(budget.maxBytes)}',
    );
  }
}

int _directorySize(Directory directory) {
  var total = 0;
  for (final FileSystemEntity entity in directory.listSync(recursive: true)) {
    if (entity is File) {
      total += entity.lengthSync();
    }
  }
  return total;
}

String _formatBytes(int bytes) {
  if (bytes >= _mib) {
    return '${(bytes / _mib).toStringAsFixed(1)} MiB';
  }
  return '${(bytes / 1024).toStringAsFixed(1)} KiB';
}

final class _Budget {
  const _Budget({required this.label, required this.maxBytes});

  final String label;
  final int maxBytes;
}
