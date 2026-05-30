// Short user-facing strings for sign-in and restore flows.
import 'dart:io';

import 'l10n/app_localizations.dart';

/// When Google sign-in fails — SnackBar / inline message (Android only).
String googleSignInErrorForUser(AppLocalizations l, Object error) {
  final raw = error.toString().toLowerCase();
  if (raw.contains('sign_in_canceled') || raw.contains('cancel')) {
    return l.signInCanceled;
  }
  if (raw.contains('apiexception: 10') ||
      raw.contains('developer_error') ||
      raw.contains('sign_in_failed')) {
    return l.googleSignInFailedRetry;
  }
  return l.googleSignInGenericError;
}

/// After “Restore purchases” when no Premium is found.
String proRestoreNotFoundForUser(AppLocalizations l) {
  if (Platform.isIOS) {
    return l.proRestoreNotFoundIos;
  }
  return l.proRestoreNotFoundAndroid;
}
