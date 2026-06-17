import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../infrastructure/consent/consent_service.dart';
import '../../../infrastructure/save/save_repository.dart';
import '../consent/consent_panel.dart';

final class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayerSave save = ref.watch(playerSaveProvider);
    final ConsentState consentState = ConsentState.values.byName(
      save.settings.consentState,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          SwitchListTile(
            value: save.music,
            onChanged: (bool value) =>
                _update(ref, save.copyWith(music: value)),
            title: const Text('Music'),
          ),
          SwitchListTile(
            value: save.sfx,
            onChanged: (bool value) => _update(ref, save.copyWith(sfx: value)),
            title: const Text('SFX'),
          ),
          SwitchListTile(
            value: save.haptics,
            onChanged: (bool value) =>
                _update(ref, save.copyWith(haptics: value)),
            title: const Text('Haptics'),
          ),
          SwitchListTile(
            value: save.reduceMotion,
            onChanged: (bool value) =>
                _update(ref, save.copyWith(reduceMotion: value)),
            title: const Text('Reduce Motion'),
          ),
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
