import 'package:flutter/material.dart';

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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Paused',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _ActionButton(
              icon: Icons.play_arrow_rounded,
              label: 'Resume',
              onPressed: onResume,
            ),
            _ActionButton(
              icon: Icons.refresh_rounded,
              label: 'Restart',
              onPressed: onRestart,
            ),
            _ActionButton(
              icon: Icons.settings_rounded,
              label: 'Settings',
              onPressed: onSettings,
            ),
            _ActionButton(
              icon: Icons.map_rounded,
              label: 'Exit to Map',
              onPressed: onExitToMap,
            ),
            if (onDebug != null)
              _ActionButton(
                icon: Icons.analytics_outlined,
                label: 'Debug Analytics',
                onPressed: onDebug!,
              ),
          ],
        ),
      ),
    );
  }
}

final class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}
