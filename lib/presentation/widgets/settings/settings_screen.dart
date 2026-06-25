import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../infrastructure/consent/consent_service.dart';
import '../../../infrastructure/save/save_repository.dart';
import '../../design/game_colors.dart';
import '../../design/game_surfaces.dart';
import '../../design/game_typography.dart';
import '../consent/consent_panel.dart';
import '../cozy/cozy_widgets.dart';

final class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayerSave save = ref.watch(playerSaveProvider);
    final ConsentState consentState = ConsentState.values.byName(
      save.settings.consentState,
    );
    return Scaffold(
      backgroundColor: GameColors.bgBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 64,
        titleSpacing: 16,
        title: Row(
          children: <Widget>[
            const CozyTitle('Settings', fontSize: 30),
            const Spacer(),
            CozyIconButton(
              asset: 'btn/clear-x.png',
              size: 44,
              tooltip: 'Close',
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: <Widget>[
          DecoratedBox(
            decoration: GameSurfaces.panel(),
            child: Column(
              children: <Widget>[
                _CozyToggleRow(
                  icon: cozyAsset('ui/note.png'),
                  label: 'Music',
                  value: save.music,
                  onChanged: (bool value) =>
                      _update(ref, save.copyWith(music: value)),
                ),
                _Divider(),
                _CozyToggleRow(
                  icon: cozyAsset('ui/som.png'),
                  label: 'Sound FX',
                  value: save.sfx,
                  onChanged: (bool value) =>
                      _update(ref, save.copyWith(sfx: value)),
                ),
                _Divider(),
                _CozyToggleRow(
                  icon: cozyAsset('icon/ray.png'),
                  label: 'Vibration',
                  value: save.haptics,
                  onChanged: (bool value) =>
                      _update(ref, save.copyWith(haptics: value)),
                ),
                _Divider(),
                _CozyToggleRow(
                  icon: cozyAsset('icon/ray.png'),
                  label: 'Reduce Motion',
                  value: save.reduceMotion,
                  onChanged: (bool value) =>
                      _update(ref, save.copyWith(reduceMotion: value)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ConsentPanel(
            state: consentState,
            onChanged: (ConsentState value) {
              _updateConsent(ref, save, value);
            },
          ),
        ],
      ),
    );
  }

  void _update(WidgetRef ref, PlayerSave save) {
    ref.read(playerSaveProvider.notifier).state = save;
    unawaited(ref.read(saveRepositoryProvider).save(save));
  }

  void _updateConsent(WidgetRef ref, PlayerSave save, ConsentState state) {
    ref.read(consentServiceProvider).update(state);
    _update(ref, save.copyWith(consentState: state.name));
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 2,
      thickness: 2,
      color: GameColors.divider,
      indent: 0,
      endIndent: 0,
    );
  }
}

class _CozyToggleRow extends StatelessWidget {
  const _CozyToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            Image.asset(
              icon,
              width: 26,
              height: 26,
              fit: BoxFit.contain,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stack) =>
                      const SizedBox(width: 26, height: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: GameTypography.body),
            ),
            _CozyToggle(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _CozyToggle extends StatelessWidget {
  const _CozyToggle({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  static const double _trackW = 56;
  static const double _trackH = 31;
  static const double _knobSize = 23;
  static const double _borderWidth = 3;
  // padding so knob stays inside track with the 3px border
  static const double _pad = (_trackH - _knobSize) / 2;

  @override
  Widget build(BuildContext context) {
    final Color trackColor = value ? GameColors.leaf : GameColors.toggleOff;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: SizedBox(
        width: _trackW,
        height: _trackH,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: GameColors.ink, width: _borderWidth),
            boxShadow: value
                ? <BoxShadow>[
                    BoxShadow(
                      color: GameColors.leafLip,
                      offset: const Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: <Widget>[
              AnimatedAlign(
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeInOut,
                child: Padding(
                  padding: EdgeInsets.all(_pad),
                  child: SizedBox(
                    width: _knobSize,
                    height: _knobSize,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: GameColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: GameColors.ink,
                          width: _borderWidth,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
