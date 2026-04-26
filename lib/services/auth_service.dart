import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Manages Google Sign-In, anonymous → Google account linking, and
/// cloud-backup of the Pro unlock status in Firestore.
///
/// NOTE: `isPro` is NEVER written directly from the client to Firestore.
/// Only the Admin SDK (Cloud Function) may set that field.
/// The client only reads `isPro` to restore entitlements after reinstall.
class AuthService {
  AuthService();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isSignedInWithGoogle =>
      _auth.currentUser?.providerData
          .any((p) => p.providerId == 'google.com') ??
      false;
  String? get displayName => _auth.currentUser?.displayName;
  String? get email => _auth.currentUser?.email;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Signs in with Google.
  /// If the current user is anonymous, links the anonymous account to Google
  /// so the UID stays the same (Firestore duel data preserved).
  /// Returns the signed-in [User], or null on cancel / failure.
  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final current = _auth.currentUser;

      if (current != null && current.isAnonymous) {
        try {
          final result = await current.linkWithCredential(credential);
          if (kDebugMode) {
            debugPrint('Auth: anonymous account linked to Google');
          }
          return result.user;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            final result = await _auth.signInWithCredential(credential);
            if (kDebugMode) {
              debugPrint('Auth: signed in with existing Google account');
            }
            return result.user;
          }
          rethrow;
        }
      } else {
        final result = await _auth.signInWithCredential(credential);
        if (kDebugMode) debugPrint('Auth: signed in with Google');
        return result.user;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Auth: signInWithGoogle failed — $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    await _auth.signInAnonymously();
  }

  // ---------------------------------------------------------------------------
  // Firestore Pro sync (read-only from client)
  // ---------------------------------------------------------------------------

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  /// Reads isPro from Firestore for the current user.
  /// This value is ONLY set by the server-side Cloud Function after
  /// verifying the Play purchase token — never by the client.
  /// Returns false if not signed in, no record found, or read fails.
  Future<bool> fetchProFromCloud() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    try {
      final snap = await _userDoc(uid).get();
      return snap.data()?['isPro'] == true;
    } catch (e) {
      if (kDebugMode) debugPrint('Auth: fetchProFromCloud failed — $e');
      return false;
    }
  }

  /// Notifies the server that a purchase occurred so it can verify
  /// via the Play Developer API and write isPro to Firestore.
  /// Falls back silently — local SecureStorage is the primary entitlement store.
  Future<void> notifyPurchaseToServer({
    required String purchaseToken,
    required String productId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      // Write a pending verification request that the Cloud Function processes.
      // The function verifies with Play Developer API and writes isPro.
      await _db.collection('purchase_verifications').add({
        'uid': uid,
        'purchaseToken': purchaseToken,
        'productId': productId,
        'requestedAt': FieldValue.serverTimestamp(),
        'verified': false,
      });
      if (kDebugMode) debugPrint('Auth: purchase verification request sent');
    } catch (e) {
      if (kDebugMode) debugPrint('Auth: notifyPurchaseToServer failed — $e');
    }
  }
}
