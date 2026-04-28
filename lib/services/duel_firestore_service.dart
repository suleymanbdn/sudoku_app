import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase_bootstrap.dart';

/// Synced head-to-head race (Firestore). No-op when Firebase is not configured.
class DuelFirestoreService {
  DuelFirestoreService();

  bool get isReady => firebaseDuelBackendReady;

  FirebaseFirestore? get _db {
    if (!isReady) return null;
    return FirebaseFirestore.instance;
  }

  Future<void> createOnlineRoom({
    required String roomCode,
    required int seed,
    required int difficultyIndex,
    required String hostId,
  }) async {
    final db = _db;
    if (db == null) return;
    await db.collection('duel_matches').doc(roomCode).set({
      'seed': seed,
      'difficultyIndex': difficultyIndex,
      'hostId': hostId,
      'phase': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> joinOnlineRoom({
    required String roomCode,
    required String guestId,
  }) async {
    final db = _db;
    if (db == null) return false;
    final ref = db.collection('duel_matches').doc(roomCode);
    try {
      return await db.runTransaction<bool>((transaction) async {
        final snap = await transaction.get(ref);
        if (!snap.exists) return false;
        final phase = snap.data()?['phase'];
        final phaseStr = phase is String ? phase : '';
        if (phaseStr == 'playing') {
          return false;
        }
        final patch = <String, dynamic>{'guestId': guestId};
        if (phaseStr == 'waiting') {
          patch['phase'] = 'ready';
        }
        transaction.update(ref, patch);
        return true;
      });
    } catch (_) {
      return false;
    }
  }

  Future<void> startOnlineRace(String roomCode) async {
    final db = _db;
    if (db == null) return;
    await db.collection('duel_matches').doc(roomCode).update({
      'phase': 'playing',
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reportFinish({
    required String roomCode,
    required bool isHost,
  }) async {
    final db = _db;
    if (db == null) return;
    final field = isHost ? 'hostDone' : 'guestDone';
    await db.collection('duel_matches').doc(roomCode).update({
      field: FieldValue.serverTimestamp(),
    });
  }

  Future<void> reportForfeit({
    required String roomCode,
    required bool isHost,
  }) async {
    final db = _db;
    if (db == null) return;
    final field = isHost ? 'hostForfeit' : 'guestForfeit';
    await db.collection('duel_matches').doc(roomCode).update({
      field: true,
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>? watchRoom(String roomCode) {
    final db = _db;
    if (db == null) return null;
    return db.collection('duel_matches').doc(roomCode).snapshots();
  }
}
