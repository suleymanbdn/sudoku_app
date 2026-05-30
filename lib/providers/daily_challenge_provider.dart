import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_provider.dart' show sharedPreferencesProvider;

const _kDcDoneKey = 'daily_challenge_v1_done'; // 'yyyy-MM-dd'
const _kDcTimeKey = 'daily_challenge_v1_time'; // int (seconds)
const _kDcMistakesKey = 'daily_challenge_v1_mistakes'; // int
const _kDcStreakKey = 'daily_challenge_v1_streak'; // int
const _kDcLastDateKey = 'daily_challenge_v1_last_date'; // 'yyyy-MM-dd'

/// Returns a deterministic seed for today's daily challenge.
/// Example: 2026-05-09 → 20260509
int dailyChallengeSeed() {
  final now = DateTime.now();
  return now.year * 10000 + now.month * 100 + now.day;
}

String _todayStr() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String _yesterdayStr() {
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  return '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
}

class DailyChallengeState {
  const DailyChallengeState({
    required this.today,
    required this.completedToday,
    this.bestTimeSeconds,
    this.bestMistakes,
    this.streak = 0,
  });

  final String today;
  final bool completedToday;
  final int? bestTimeSeconds;
  final int? bestMistakes;
  final int streak;

  DailyChallengeState copyWith({
    String? today,
    bool? completedToday,
    int? bestTimeSeconds,
    int? bestMistakes,
    int? streak,
  }) =>
      DailyChallengeState(
        today: today ?? this.today,
        completedToday: completedToday ?? this.completedToday,
        bestTimeSeconds: bestTimeSeconds ?? this.bestTimeSeconds,
        bestMistakes: bestMistakes ?? this.bestMistakes,
        streak: streak ?? this.streak,
      );
}

class DailyChallengeNotifier extends StateNotifier<DailyChallengeState> {
  DailyChallengeNotifier(SharedPreferences prefs)
      : _prefs = prefs,
        super(DailyChallengeState(today: _todayStr(), completedToday: false)) {
    _load();
  }

  final SharedPreferences _prefs;

  void _load() {
    final today = _todayStr();
    final doneDate = _prefs.getString(_kDcDoneKey);
    final completedToday = doneDate == today;
    final time = completedToday ? _prefs.getInt(_kDcTimeKey) : null;
    final mistakes = completedToday ? _prefs.getInt(_kDcMistakesKey) : null;
    final streak = _prefs.getInt(_kDcStreakKey) ?? 0;
    state = DailyChallengeState(
      today: today,
      completedToday: completedToday,
      bestTimeSeconds: time,
      bestMistakes: mistakes,
      streak: streak,
    );
  }

  Future<void> recordCompletion(int timeSeconds, int mistakes) async {
    final today = _todayStr();
    // Idempotent: don't re-record if already done today
    if (state.completedToday && state.today == today) return;

    // Streak calculation
    final lastDate = _prefs.getString(_kDcLastDateKey);
    final yesterday = _yesterdayStr();
    int newStreak;
    if (lastDate == yesterday) {
      newStreak = state.streak + 1;
    } else if (lastDate == today) {
      newStreak = state.streak; // Already recorded, keep current
    } else {
      newStreak = 1;
    }

    await _prefs.setString(_kDcDoneKey, today);
    await _prefs.setInt(_kDcTimeKey, timeSeconds);
    await _prefs.setInt(_kDcMistakesKey, mistakes);
    await _prefs.setInt(_kDcStreakKey, newStreak);
    await _prefs.setString(_kDcLastDateKey, today);

    state = DailyChallengeState(
      today: today,
      completedToday: true,
      bestTimeSeconds: timeSeconds,
      bestMistakes: mistakes,
      streak: newStreak,
    );
  }
}

final dailyChallengeProvider =
    StateNotifierProvider<DailyChallengeNotifier, DailyChallengeState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DailyChallengeNotifier(prefs);
});
