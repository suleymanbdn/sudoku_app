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

bool _firebaseInitStarted = false;

bool get _productionFirebaseOptionsFilled =>
    DefaultFirebaseOptions.android.projectId.isNotEmpty &&
    DefaultFirebaseOptions.android.apiKey.isNotEmpty;

/// Firestore is usable for duels (production keys or local emulator build).
bool get firebaseDuelBackendReady =>
    Firebase.apps.isNotEmpty &&
    (kDuelFirestoreEmulator || _productionFirebaseOptionsFilled);

Future<void> initializeFirebaseForApp() async {
  _assertEmulatorSafeForRelease();
  if (_firebaseInitStarted) return;

  if (Firebase.apps.isNotEmpty) {
    _firebaseInitStarted = true;
    return;
  }

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
      final opts = DefaultFirebaseOptions.currentPlatform;
      await Firebase.initializeApp(options: opts);
      await _activateAppCheck();
      await _ensureAnonymousAuth();
    } on UnsupportedError catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase: platform not in firebase_options.dart — $e');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Firebase.initializeApp failed: $e\n$st');
      }
    }
  }
  _firebaseInitStarted = true;
}

/// Activates Firebase App Check with Play Integrity (release) or debug token (debug).
/// Prevents non-app clients from calling Firestore / Auth with our API keys.
Future<void> _activateAppCheck() async {
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
    );
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
