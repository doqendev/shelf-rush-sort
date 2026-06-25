import 'package:flutter/material.dart';

import '../../design/game_typography.dart';
import '../cozy/cozy_widgets.dart';

final class PauseSheet extends StatelessWidget {
  const PauseSheet({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onSettings,
    required this.onExitToMap,
    this.onDebug,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onSettings;
  final VoidCallback onExitToMap;
  final VoidCallback? onDebug;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CozyTitle('PAUSED', fontSize: 34),
            const SizedBox(height: 18),
            CozyButton(label: 'RESUME', onTap: onResume),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _IconAction(
                  asset: 'btn/clear-return.png',
                  label: 'Restart',
                  onTap: onRestart,
                ),
                _IconAction(
                  asset: 'btn/clear-setting.png',
                  label: 'Settings',
                  onTap: onSettings,
                ),
                _IconAction(
                  asset: 'btn/grass-house.png',
                  label: 'Home',
                  onTap: onExitToMap,
                ),
                if (onDebug != null)
                  _IconAction(
                    asset: 'btn/clear-note.png',
                    label: 'Debug',
                    onTap: onDebug!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.asset,
    required this.label,
    required this.onTap,
  });

  final String asset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CozyIconButton(asset: asset, onTap: onTap, size: 58),
        const SizedBox(height: 5),
        Text(label, style: GameTypography.compactLabel.copyWith(fontSize: 12)),
      ],
    );
  }
}
