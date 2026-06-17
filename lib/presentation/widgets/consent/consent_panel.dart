import 'package:flutter/material.dart';

import '../../../infrastructure/consent/consent_service.dart';

final class ConsentPanel extends StatelessWidget {
  const ConsentPanel({super.key, required this.state, required this.onChanged});

  final ConsentState state;
  final ValueChanged<ConsentState> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.privacy_tip_outlined),
              title: Text('Consent'),
            ),
            SegmentedButton<ConsentState>(
              segments: const <ButtonSegment<ConsentState>>[
                ButtonSegment<ConsentState>(
                  value: ConsentState.unknown,
                  icon: Icon(Icons.help_outline),
                  label: Text('Unknown'),
                ),
                ButtonSegment<ConsentState>(
                  value: ConsentState.granted,
                  icon: Icon(Icons.check_circle_outline),
                  label: Text('Granted'),
                ),
                ButtonSegment<ConsentState>(
                  value: ConsentState.denied,
                  icon: Icon(Icons.block_outlined),
                  label: Text('Denied'),
                ),
              ],
              selected: <ConsentState>{state},
              onSelectionChanged: (Set<ConsentState> selection) {
                onChanged(selection.single);
              },
            ),
          ],
        ),
      ),
    );
  }
}
