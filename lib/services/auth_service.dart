import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Web OAuth client ID from `android/app/google-services.json` (`client_type` 3).
/// Required on Android so [GoogleSignInAuthentication.idToken] is non-null for Firebase.
const _kGoogleServerClientId =
    '1080698565810-mcpeq6muvi9uf8r14vap6t91a7404l94.apps.googleusercontent.com';

/// Manages Google Sign-In, Sign in with Apple, anonymous → social account
/// linking, and cloud-backup of the Pro unlock status in Firestore.
///
/// NOTE: `isPro` is NEVER written directly from the client to Firestore.
/// Only the Admin SDK (Cloud Function) may set that field.
/// The client only reads `isPro` to restore entitlements after reinstall.
class AuthService {
  AuthService();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: _kGoogleServerClientId,
  );
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isSignedInWithGoogle =>
      _auth.currentUser?.providerData
          .any((p) => p.providerId == 'google.com') ??
      false;
  bool get isSignedInWithApple =>
      _auth.currentUser?.providerData
          .any((p) => p.providerId == 'apple.com') ??
      false;
  String? get displayName => _auth.currentUser?.displayName;
  String? get email => _auth.currentUser?.email;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ---------------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------------

  /// Signs in with Google.
  /// If the current user is anonymous, links the anonymous account to Google
  /// so the UID stays the same (Firestore data preserved).
  /// Returns the signed-in [User], or null on cancel / failure.
  Future<User?> signInWithGoogle() async {
    try {
      // On some devices a stale Google session can make signIn() appear stuck.
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null && googleAuth.accessToken == null) {
        if (kDebugMode) {
          debugPrint(
            'Auth: Google idToken/accessToken null — check serverClientId / SHA-1',
          );
        }
        return null;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return _linkOrSignIn(credential);
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled') {
        return null;
      }
      if (kDebugMode) {
        debugPrint(
          'Auth: signInWithGoogle PlatformException — ${e.code} ${e.message}',
        );
      }
      rethrow;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Auth: signInWithGoogle failed — $e');
        debugPrint('$st');
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Sign in with Apple
  // ---------------------------------------------------------------------------

  /// Signs in with Apple using Firebase Auth.
  /// Required by Apple when any third-party social login is offered.
  /// Returns the signed-in [User], or null on cancel / failure.
  Future<User?> signInWithApple() async {
    try {
      // Generate a nonce to prevent replay attacks.
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      return _linkOrSignIn(oauthCredential);
    } on SignInWithAppleAuthorizationException catch (e) {
      // User canceled the Apple auth sheet — not an error, return null silently.
      if (e.code == AuthorizationErrorCode.canceled) return null;
      if (kDebugMode) {
        debugPrint('Auth: signInWithApple authorization error — ${e.code}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) debugPrint('Auth: signInWithApple failed — $e');
      rethrow;
    }
  }

  /// Links anonymous account to [credential], or signs in directly.
  Future<User?> _linkOrSignIn(AuthCredential credential) async {
    final current = _auth.currentUser;
    if (current != null && current.isAnonymous) {
      try {
        final result = await current.linkWithCredential(credential);
        if (kDebugMode) debugPrint('Auth: anonymous account linked');
        return result.user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          final result = await _auth.signInWithCredential(credential);
          if (kDebugMode) debugPrint('Auth: signed in with existing account');
          return result.user;
        }
        rethrow;
      }
    } else {
      final result = await _auth.signInWithCredential(credential);
      if (kDebugMode) debugPrint('Auth: signed in');
      return result.user;
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
  /// verifying the purchase token — never by the client.
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
  /// and write isPro to Firestore.
  /// Falls back silently — local SecureStorage is the primary entitlement store.
  Future<void> notifyPurchaseToServer({
    required String purchaseToken,
    required String productId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
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

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
