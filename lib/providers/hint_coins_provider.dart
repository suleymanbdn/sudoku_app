import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_provider.dart'; // for sharedPreferencesProvider

const _kHintCoinsKey = 'hint_coins_v1';

// ── Provider ─────────────────────────────────────────────────────────────────

final hintCoinsProvider =
    StateNotifierProvider<HintCoinsNotifier, int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HintCoinsNotifier(prefs);
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class HintCoinsNotifier extends StateNotifier<int> {
  HintCoinsNotifier(SharedPreferences prefs)
      : _prefs = prefs,
        super(prefs.getInt(_kHintCoinsKey) ?? 0);

  final SharedPreferences _prefs;

  /// Add coins after a hint pack purchase.
  void addCoins(int amount) {
    final next = state + amount;
    state = next;
    _prefs.setInt(_kHintCoinsKey, next);
  }

  /// Deduct one coin when the user uses a coin-hint.
  /// Returns `true` if successful, `false` if no coins available.
  bool useOneCoin() {
    if (state <= 0) return false;
    final next = state - 1;
    state = next;
    _prefs.setInt(_kHintCoinsKey, next);
    return true;
  }
}
