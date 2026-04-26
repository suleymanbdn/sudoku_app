// Not overwritten by `flutterfire configure` — keep local duel emulator keys here.
//
// ignore_for_file: lines_longer_than_80_chars

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Matches [firebase.json] project id `demo-sudoku-duel` (local emulator only).
abstract final class FirebaseEmulatorOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'emulator-does-not-call-remote',
    appId: '1:1000010000100:android:dueldev0000000000001',
    messagingSenderId: '1000010000100',
    projectId: 'demo-sudoku-duel',
    storageBucket: 'demo-sudoku-duel.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'emulator-does-not-call-remote',
    appId: '1:1000010000100:ios:dueldev0000000000001',
    messagingSenderId: '1000010000100',
    projectId: 'demo-sudoku-duel',
    storageBucket: 'demo-sudoku-duel.appspot.com',
    iosBundleId: 'com.sudokubulmaca.app',
  );
}
