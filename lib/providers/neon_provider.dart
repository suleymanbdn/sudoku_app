import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'purchase_provider.dart';
import 'theme_provider.dart';

const _kNeonEffectsKey = 'neon_effects';

final neonEffectsNotifierProvider =
    StateNotifierProvider<NeonEffectsNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NeonEffectsNotifier(ref, prefs);
});

/// Whether neon grid glow is shown (Pro + user preference).
final neonEffectsActiveProvider = Provider<bool>((ref) {
  final pref = ref.watch(neonEffectsNotifierProvider);
  final pro = ref.watch(isProSyncProvider);
  return pref && pro;
});

class NeonEffectsNotifier extends StateNotifier<bool> {
  NeonEffectsNotifier(this._ref, this._prefs) : super(_read(_prefs)) {
    _purgeIfNeeded(_ref.read(isProProvider));
    _ref.listen<AsyncValue<bool>>(isProProvider, (_, next) {
      _purgeIfNeeded(next);
    });
  }

  final Ref _ref;
  final SharedPreferences _prefs;

  static bool _read(SharedPreferences prefs) =>
      prefs.getBool(_kNeonEffectsKey) ?? false;

  void _purgeIfNeeded(AsyncValue<bool> async) {
    if (async.hasValue && !async.requireValue && state) {
      _clearIfNotPro();
    }
  }

  void _clearIfNotPro() {
    if (!state) return;
    state = false;
    _prefs.setBool(_kNeonEffectsKey, false);
  }

  Future<void> setEnabled(bool value) async {
    if (value && !_ref.read(isProSyncProvider)) return;
    state = value;
    await _prefs.setBool(_kNeonEffectsKey, value);
  }
}
