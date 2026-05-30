import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/theme_presets.dart';

const _kThemeIdKey = 'app_theme_id';
const _kBrightnessKey = 'app_brightness';

/// Overridden in [main] with real [SharedPreferences].
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

class ThemeIdNotifier extends StateNotifier<AppThemeId> {
  ThemeIdNotifier(this._prefs) : super(_readInitial(_prefs));

  final SharedPreferences _prefs;

  static AppThemeId _readInitial(SharedPreferences prefs) {
    final stored = prefs.getString(_kThemeIdKey);
    if (stored == null) return AppThemeId.midnight;
    return AppThemeId.values.firstWhere(
      (e) => e.name == stored,
      orElse: () => AppThemeId.midnight,
    );
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

class BrightnessNotifier extends StateNotifier<AppBrightness> {
  BrightnessNotifier(this._prefs) : super(_readInitial(_prefs));

  final SharedPreferences _prefs;

  static AppBrightness _readInitial(SharedPreferences prefs) {
    final stored = prefs.getString(_kBrightnessKey);
    if (stored == null) return AppBrightness.dark;
    return AppBrightness.values.firstWhere(
      (e) => e.name == stored,
      orElse: () => AppBrightness.dark,
    );
  }

  Future<void> setBrightness(AppBrightness value) async {
    state = value;
    await _prefs.setString(_kBrightnessKey, value.name);
  }
}

final brightnessProvider =
    StateNotifierProvider<BrightnessNotifier, AppBrightness>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return BrightnessNotifier(prefs);
});
