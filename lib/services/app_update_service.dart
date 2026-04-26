import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kUpdateSnoozeUntilMs = 'update_prompt_snooze_until_ms';

/// Play in-app updates (Android only). No-op on other platforms.
class AppUpdateService {
  AppUpdateService(this._prefs);

  final SharedPreferences _prefs;

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool _isSnoozed() {
    final until = _prefs.getInt(_kUpdateSnoozeUntilMs);
    if (until == null) return false;
    return DateTime.now().millisecondsSinceEpoch < until;
  }

  Future<void> snoozePrompt({Duration duration = const Duration(days: 1)}) async {
    final until = DateTime.now().add(duration).millisecondsSinceEpoch;
    await _prefs.setInt(_kUpdateSnoozeUntilMs, until);
  }

  /// Calls Play Core after [checkForUpdate]. Returns null if not Android,
  /// snoozed, or the check throws (debug/sideload).
  Future<AppUpdateInfo?> fetchPlayUpdateInfo() async {
    if (!_isAndroid) return null;
    if (_isSnoozed()) return null;
    try {
      return await InAppUpdate.checkForUpdate();
    } catch (_) {
      return null;
    }
  }

  bool isUpdateAvailable(AppUpdateInfo? info) {
    if (info == null) return false;
    return info.updateAvailability == UpdateAvailability.updateAvailable;
  }

  Future<AppUpdateResult> performImmediateUpdate() async {
    return InAppUpdate.performImmediateUpdate();
  }
}
