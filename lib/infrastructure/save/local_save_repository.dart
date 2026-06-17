import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'save_repository.dart';

final class LocalSaveRepository implements SaveRepository {
  LocalSaveRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _key = 'shelf_rush_sort_player_save';

  final SharedPreferencesAsync _preferences;

  @override
  Future<PlayerSave?> load() async {
    final String? raw = await _preferences.getString(_key);
    if (raw == null) {
      return null;
    }
    return PlayerSave.fromJson(jsonDecode(raw) as Map<String, Object?>);
  }

  @override
  Future<void> save(PlayerSave save) async {
    await _preferences.setString(_key, jsonEncode(save.toJson()));
  }
}
