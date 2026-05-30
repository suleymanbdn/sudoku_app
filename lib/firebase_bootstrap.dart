import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_emulator_options.dart';
import 'firebase_options.dart';

// Safety check: emulator must never be enabled in a release build.
// If DUEL_USE_EMULATOR is mistakenly passed during a release compile, this
// assertion surfaces at startup rather than silently routing to a dev host.
void _assertEmulatorSafeForRelease() {
  assert(
    !(kReleaseMode && kDuelFirestoreEmulator),
    'DUEL_USE_EMULATOR must not be true in a release build.',
  );
}

/// Set by [tool/run_online_duel_dev.ps1] / `.vscode/launch.json` for local Firestore.
const bool kDuelFirestoreEmulator = bool.fromEnvironment(
  'DUEL_USE_EMULATOR',
  defaultValue: false,
);

/// When non-empty, used instead of the default loopback host (needed for a physical phone).
const String kDuelEmulatorHostOverride = String.fromEnvironment(
  'DUEL_EMULATOR_HOST',
  defaultValue: '',
);

/// Turned on with `flutter run --dart-define=USE_APP_CHECK_DEBUG=true`; register the
/// debug token in Firebase Console. Default **false**: App Check off in local debug
/// (Firestore App Check “Enforce” without a debug token causes repeated permission-denied).
const bool kUseAppCheckInDebug = bool.fromEnvironment(
  'USE_APP_CHECK_DEBUG',
  defaultValue: false,
);

bool _firebaseInitStarted = false;

bool get _productionFirebaseOptionsFilled =>
    DefaultFirebaseOptions.android.projectId.isNotEmpty &&
    DefaultFirebaseOptions.android.apiKey.isNotEmpty;

/// Firestore is usable for duels (production keys or local emulator build).
bool get firebaseDuelBackendReady =>
    Firebase.apps.isNotEmpty &&
    (kDuelFirestoreEmulator || _productionFirebaseOptionsFilled);

/// Initializes Firebase Core synchronously (no network). Fast, safe for
/// blocking the splash screen. Network-dependent tasks (App Check, anonymous
/// auth) are kicked off in the background via [initializeFirebaseNetworkTasks].
Future<void> initializeFirebaseForApp() async {
  _assertEmulatorSafeForRelease();
  if (_firebaseInitStarted) return;

  if (kDuelFirestoreEmulator) {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      if (kDebugMode) {
        debugPrint(
          'DUEL_USE_EMULATOR: only Android/iOS are wired; skipping Firebase.',
        );
      }
      _firebaseInitStarted = true;
      return;
    }
    try {
      final options = defaultTargetPlatform == TargetPlatform.iOS
          ? FirebaseEmulatorOptions.ios
          : FirebaseEmulatorOptions.android;
      await Firebase.initializeApp(options: options);
      final host = kDuelEmulatorHostOverride.isNotEmpty
          ? kDuelEmulatorHostOverride
          : _defaultFirestoreEmulatorHost();
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
      if (kDebugMode) {
        debugPrint('Firestore emulator: $host:8080');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Firebase emulator init failed: $e\n$st');
      }
    }
    _firebaseInitStarted = true;
    return;
  }

  if (!kDuelFirestoreEmulator && _productionFirebaseOptionsFilled) {
    try {
      if (Firebase.apps.isEmpty) {
        final opts = DefaultFirebaseOptions.currentPlatform;
        try {
          await Firebase.initializeApp(options: opts);
        } catch (e, st) {
          // Dart may see no apps while the plugin/native layer already has
          // [DEFAULT] registered (reconnect / process reuse). Swallow duplicate-app
          // and continue with App Check + auth; otherwise Firestore may stay
          // PERMISSION_DENIED (no App Check).
          final duplicate = e is FirebaseException && e.code == 'duplicate-app' ||
              e.toString().contains('duplicate-app');
          if (duplicate) {
            if (kDebugMode) {
              debugPrint('Firebase: duplicate-app — continuing with App Check.');
            }
          } else {
            if (kDebugMode) {
              debugPrint('Firebase.initializeApp failed: $e\n$st');
            }
          }
        }
      } else if (kDebugMode) {
        debugPrint(
          'Firebase: [DEFAULT] already exists — skipping initializeApp; '
          'running App Check + auth (hot restart / native reuse).',
        );
      }
      // Network tasks (App Check + anonymous auth) run in background after the
      // app launches — they must NOT block the splash screen.
      unawaited(initializeFirebaseNetworkTasks());
    } on UnsupportedError catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase: platform not in firebase_options.dart — $e');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Firebase bootstrap (prod) failed: $e\n$st');
      }
    }
  }
  _firebaseInitStarted = true;
}

/// Network-dependent Firebase tasks: App Check activation and anonymous auth.
/// Called in the background after [initializeFirebaseForApp] so the UI
/// appears immediately and the app is never blocked on network.
Future<void> initializeFirebaseNetworkTasks() async {
  try {
    // App Check: 8-second timeout so it never hangs indefinitely.
    await _activateAppCheck().timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        if (kDebugMode) debugPrint('Firebase: App Check activation timed out.');
      },
    );
    // Anonymous auth: 8-second timeout.
    await _ensureAnonymousAuth().timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        if (kDebugMode) debugPrint('Firebase: anonymous auth timed out.');
      },
    );
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('Firebase network tasks failed: $e\n$st');
    }
  }
}

/// Release: Play Integrity. Debug: off by default — even if Firestore App Check “Enforce”
/// is on, requests may be accepted without a token **only** when that API is in Monitoring
/// (not enforce) in Console; otherwise temporarily turn off Enforce in Console.
///
/// Debug with a token: `USE_APP_CHECK_DEBUG=true` + register debug token in Console.
Future<void> _activateAppCheck() async {
  if (kDebugMode && !kUseAppCheckInDebug) {
    if (kDebugMode) {
      debugPrint(
        'App Check: disabled in debug. If Firestore still returns permission-denied, '
        'Firebase Console → App Check → Cloud Firestore: turn off Enforce or use '
        'Monitoring only. Optional: flutter run --dart-define=USE_APP_CHECK_DEBUG=true '
        'and register a debug token.',
      );
    }
    return;
  }
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: (kDebugMode && kUseAppCheckInDebug)
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      // DeviceCheck works on all iOS 11+ devices without special entitlements.
      // AppAttest requires com.apple.developer.devicecheck.appattest-environment
      // which is not yet configured in the provisioning profile.
      appleProvider: (kDebugMode && kUseAppCheckInDebug)
          ? AppleProvider.debug
          : AppleProvider.deviceCheck,
    );
    if (kDebugMode && kUseAppCheckInDebug) {
      try {
        final t = await FirebaseAppCheck.instance.getToken();
        if (t != null) {
          debugPrint(
            'App Check DEBUG token (Firebase Console → App Check → '
            'Manage debug tokens): $t',
          );
        }
      } catch (e) {
        debugPrint('App Check getToken: $e');
      }
    }
  } catch (e) {
    if (kDebugMode) debugPrint('App Check activation failed: $e');
  }
}

/// Signs in anonymously if not already authenticated.
/// The UID is stable per-device (persisted by Firebase SDK).
Future<void> _ensureAnonymousAuth() async {
  try {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
  } catch (e) {
    if (kDebugMode) debugPrint('Anonymous auth failed: $e');
  }
}

/// Returns the current Firebase Auth UID, or null if not signed in.
String? get firebaseUid => FirebaseAuth.instance.currentUser?.uid;

String _defaultFirestoreEmulatorHost() {
  if (kIsWeb) return 'localhost';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return '10.0.2.2';
  }
  return '127.0.0.1';
}
