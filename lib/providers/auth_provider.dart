import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Streams the current Firebase [User] (null = signed out / anonymous).
final authStateProvider = StreamProvider<User?>((ref) {
  final service = ref.watch(authServiceProvider);
  return service.authStateChanges;
});

/// True when the user is signed in with Google (not anonymous).
final isSignedInWithGoogleProvider = Provider<bool>((ref) {
  final service = ref.watch(authServiceProvider);
  // Re-evaluate whenever auth state changes.
  ref.watch(authStateProvider);
  return service.isSignedInWithGoogle;
});

/// Display name of the signed-in Google user, or null.
final googleDisplayNameProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authServiceProvider).displayName;
});

/// Email of the signed-in Google user, or null.
final googleEmailProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authServiceProvider).email;
});
