import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/theme_presets.dart';

const _kThemeIdKey = 'app_theme_id';

/// Overridden in [main] with real [SharedPreferences].
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

class ThemeIdNotifier extends StateNotifier<AppThemeId> {
  ThemeIdNotifier(this._prefs) : super(_readInitial(_prefs));

  final SharedPreferences _prefs;

  static AppThemeId _readInitial(SharedPreferences prefs) {
    final raw = prefs.getString(_kThemeIdKey);
    if (raw == null) return AppThemeId.sakura;
    for (final id in AppThemeId.values) {
      if (id.name == raw) return id;
    }
    return AppThemeId.sakura;
  }

  Future<void> setTheme(AppThemeId id) async {
    state = id;
    await _prefs.setString(_kThemeIdKey, id.name);
  }
}

final themeIdProvider =
    StateNotifierProvider<ThemeIdNotifier, AppThemeId>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeIdNotifier(prefs);
});
