import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../firebase_bootstrap.dart';
import '../services/duel_firestore_service.dart';
import 'theme_provider.dart';

const _kDuelPlayerIdKey = 'duel_player_id';

/// Call from [main] after [SharedPreferences.getInstance].
/// Keeps a UUID fallback for offline/local duels; online duels use [firebaseUid].
Future<void> ensureDuelPlayerId(SharedPreferences prefs) async {
  var v = prefs.getString(_kDuelPlayerIdKey);
  if (v != null && v.isNotEmpty) return;
  v = const Uuid().v4();
  await prefs.setString(_kDuelPlayerIdKey, v);
}

final duelFirestoreServiceProvider = Provider<DuelFirestoreService>(
  (ref) => DuelFirestoreService(),
);

final duelFirebaseReadyProvider = Provider<bool>(
  (ref) => ref.watch(duelFirestoreServiceProvider).isReady,
);

/// Live match document; [roomCode] empty yields a single `null` snapshot (no subscription).
final duelRoomDocStreamProvider = StreamProvider.autoDispose
    .family<DocumentSnapshot<Map<String, dynamic>>?, String>((ref, roomCode) {
  if (roomCode.isEmpty) {
    return Stream<DocumentSnapshot<Map<String, dynamic>>?>.value(null);
  }
  final stream = ref.watch(duelFirestoreServiceProvider).watchRoom(roomCode);
  if (stream == null) {
    return Stream<DocumentSnapshot<Map<String, dynamic>>?>.value(null);
  }
  return stream.map((s) => s);
});

/// For online duels uses Firebase Auth UID (bound to Firestore security rules).
/// Falls back to the local UUID for offline/local duels when Firebase is not ready.
final duelPlayerIdProvider = Provider<String>((ref) {
  final uid = firebaseUid;
  if (uid != null && uid.isNotEmpty) return uid;
  final prefs = ref.watch(sharedPreferencesProvider);
  final v = prefs.getString(_kDuelPlayerIdKey);
  if (v == null || v.isEmpty) {
    throw StateError('ensureDuelPlayerId() must run in main before runApp');
  }
  return v;
});
