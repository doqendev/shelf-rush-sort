import 'package:flutter/material.dart';

final class DebugPanel extends StatelessWidget {
  const DebugPanel({super.key, required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: <Widget>[
          for (final String line in lines)
            Text(line, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
