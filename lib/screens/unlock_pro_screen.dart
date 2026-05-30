import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/purchase_provider.dart';
import '../services/purchase_service.dart';
import '../theme/app_colors.dart';
import '../user_facing_messages.dart';

class UnlockProScreen extends ConsumerStatefulWidget {
  const UnlockProScreen({super.key});

  static Route<bool> route() => MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const UnlockProScreen(),
      );

  @override
  ConsumerState<UnlockProScreen> createState() => _UnlockProScreenState();
}

class _UnlockProScreenState extends ConsumerState<UnlockProScreen> {
  bool _loading = false;
  bool _retrying = false;
  bool _googleLoading = false;
  bool _appleLoading = false;
  String? _errorMessage;

  /// Premium unlocked — refresh provider and close screen.
  void _closeAsPurchased() {
    ref.invalidate(isProProvider);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _buy() async {
    final service = ref.read(purchaseServiceProvider);

    if (!service.canPurchase) {
      setState(() => _errorMessage =
          AppLocalizations.of(context).storeUnavailable);
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await service.buyPro();

      if (!mounted) return;
      if (service.isPro) {
        _closeAsPurchased();
      } else {
        setState(
          () => _errorMessage =
              AppLocalizations.of(context).purchaseNotConfirmed,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = AppLocalizations.of(context).purchaseFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _googleLoading = true;
      _errorMessage = null;
    });
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInWithGoogle();
      if (!mounted) return;
      if (user == null) return; // user canceled

      // no-op: loginUser kept for API compatibility
      final purchaseService = ref.read(purchaseServiceProvider);
      await purchaseService.loginUser(user.uid);
      if (!mounted) return;

      if (purchaseService.isPro) {
        ref.invalidate(isProProvider);
        _closeAsPurchased();
      } else {
        // Signed in, but no prior purchase found — new user signing in
        // for the first time. Stay on screen so they can purchase.
        ref.invalidate(isProProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage =
            googleSignInErrorForUser(AppLocalizations.of(context), e));
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _appleLoading = true;
      _errorMessage = null;
    });
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInWithApple();
      if (!mounted) return;
      if (user == null) return; // user canceled

      // no-op: loginUser kept for API compatibility
      final purchaseService = ref.read(purchaseServiceProvider);
      await purchaseService.loginUser(user.uid);
      if (!mounted) return;

      if (purchaseService.isPro) {
        ref.invalidate(isProProvider);
        _closeAsPurchased();
      } else {
        // Signed in, but no prior purchase found — new user signing in
        // for the first time. Stay on screen so they can purchase.
        ref.invalidate(isProProvider);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('_signInWithApple error: $e');
      if (mounted) {
        setState(() =>
            _errorMessage = AppLocalizations.of(context).appleSignInFailed);
      }
    } finally {
      if (mounted) setState(() => _appleLoading = false);
    }
  }

  Future<void> _retryLoad() async {
    setState(() {
      _retrying = true;
      _errorMessage = null;
    });
    try {
      final service = ref.read(purchaseServiceProvider);
      await service.retryLoadProduct();
      ref.invalidate(productPriceProvider);
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  Future<void> _restore() async {
    final service = ref.read(purchaseServiceProvider);
    final authService = ref.read(authServiceProvider);

    /// If Pro exists in Firestore, sync to local cache (even without a Play purchase).
    Future<bool> unlockFromCloud() async {
      if (!await authService.fetchProFromCloud()) return false;
      await service.initialize(force: true);
      return service.isPro;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await service.restorePurchases();

      if (service.isPro) {
        _closeAsPurchased();
        return;
      }

      if (await unlockFromCloud()) {
        _closeAsPurchased();
        return;
      }

      // Play restore updates often arrive late via purchaseStream on many devices.
      var confirmed = false;
      try {
        confirmed = await service.purchaseStream
            .where((isPro) => isPro)
            .first
            .timeout(const Duration(seconds: 45));
      } catch (_) {
        confirmed = service.isPro;
      }

      if (!confirmed) {
        await service.initialize(force: true);
        confirmed = service.isPro;
      }

      if (!mounted) return;
      if (confirmed) {
        _closeAsPurchased();
      } else {
        setState(() => _errorMessage =
            proRestoreNotFoundForUser(AppLocalizations.of(context)));
      }
    } catch (_) {
      if (mounted) {
        setState(
            () => _errorMessage = AppLocalizations.of(context).restoreFailed);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final l = AppLocalizations.of(context);
    final priceAsync = ref.watch(productPriceProvider);
    final isSocialLinked = ref.watch(isSignedInSocialProvider);

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: c.onSurface),
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [c.primary, c.dark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: c.primary.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_open_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                l.unlockProTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: c.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.unlockProSubtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  color: c.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              _FeatureRow(
                icon: Icons.lightbulb_rounded,
                label: l.featureUnlimitedHints,
                c: c,
              ),
              const SizedBox(height: 12),
              _FeatureRow(
                icon: Icons.block_rounded,
                label: l.featureNoAds,
                c: c,
              ),
              const SizedBox(height: 12),
              _FeatureRow(
                icon: Icons.electric_bolt_rounded,
                label: l.featureNeonStyle,
                c: c,
                iconColor: const Color(0xFF00F5FF),
              ),
              const SizedBox(height: 12),
              _FeatureRow(
                icon: Icons.favorite_rounded,
                label: l.featureSupportDev,
                c: c,
                iconColor: Colors.pinkAccent,
              ),
              const Spacer(),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              priceAsync.when(
                data: (price) {
                  final service = ref.read(purchaseServiceProvider);
                  final hasPrice = price != null && price.isNotEmpty;
                  if (!hasPrice) {
                    return _StoreUnavailable(
                      retrying: _retrying,
                      onRetry: _retryLoad,
                      c: c,
                      storeStatus: service.storeStatus,
                    );
                  }
                  return _BuyButton(
                    label: l.unlockForPrice(price),
                    loading: _loading,
                    onTap: _buy,
                    c: c,
                  );
                },
                loading: () => _BuyButton(
                  label: l.loadingPrice,
                  loading: true,
                  onTap: null,
                  c: c,
                ),
                error: (e, __) {
                  final service = ref.read(purchaseServiceProvider);
                  return _StoreUnavailable(
                    retrying: _retrying,
                    onRetry: _retryLoad,
                    c: c,
                    storeStatus: service.storeStatus,
                  );
                },
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: _loading ? null : _restore,
                child: Text(
                  l.restorePurchases,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: c.onSurfaceVariant,
                    decoration: TextDecoration.underline,
                    decorationColor: c.onSurfaceVariant,
                  ),
                ),
              ),
              if (!isSocialLinked) ...[
                const SizedBox(height: 4),
                // iOS: only Sign in with Apple (no third-party login → avoids Guideline 4.8)
                // Android: only Google Sign-In
                if (Platform.isIOS) ...[
                  _AppleSignInButton(
                    loading: _appleLoading,
                    onTap: (_loading || _googleLoading || _appleLoading)
                        ? null
                        : _signInWithApple,
                    c: c,
                  ),
                ] else ...[
                  _GoogleSignInButton(
                    loading: _googleLoading,
                    onTap: (_loading || _googleLoading || _appleLoading)
                        ? null
                        : _signInWithGoogle,
                    c: c,
                  ),
                ],
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.label,
    required this.c,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final AppColors c;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? c.primary;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: c.onSurface,
          ),
        ),
      ],
    );
  }
}

class _BuyButton extends StatelessWidget {
  const _BuyButton({
    required this.label,
    required this.loading,
    required this.onTap,
    required this.c,
  });

  final String label;
  final bool loading;
  final VoidCallback? onTap;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: c.primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 4,
          shadowColor: c.primary.withValues(alpha: 0.4),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class _StoreUnavailable extends StatelessWidget {
  const _StoreUnavailable({
    required this.retrying,
    required this.onRetry,
    required this.c,
    required this.storeStatus,
  });

  final bool retrying;
  final VoidCallback onRetry;
  final AppColors c;
  final StoreStatus storeStatus;

  String _messageFor(AppLocalizations l) {
    final isIOS = Platform.isIOS;
    switch (storeStatus) {
      case StoreStatus.storeUnavailable:
        return isIOS ? l.storeUnavailableIos : l.storeUnavailableAndroid;
      case StoreStatus.productNotFound:
        return isIOS ? l.productNotFoundIos : l.productNotFoundAndroid;
      case StoreStatus.queryError:
        return isIOS ? l.queryErrorIos : l.queryErrorAndroid;
      default:
        return isIOS ? l.storeInfoErrorIos : l.storeInfoErrorAndroid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.info_outline_rounded,
                    color: Colors.orange, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _messageFor(l),
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 56,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: retrying ? null : onRetry,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: c.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: retrying
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: c.primary,
                    ),
                  )
                : Icon(Icons.refresh_rounded, color: c.primary),
            label: Text(
              retrying ? l.loadingShort : l.tryAgainShort,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AppleSignInButton extends StatelessWidget {
  const _AppleSignInButton({
    required this.loading,
    required this.onTap,
    required this.c,
  });

  final bool loading;
  final VoidCallback? onTap;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return SignInWithAppleButton(
      onPressed: (loading || onTap == null) ? () {} : onTap!,
      style: SignInWithAppleButtonStyle.black,
      borderRadius: BorderRadius.circular(12),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({
    required this.loading,
    required this.onTap,
    required this.c,
  });

  final bool loading;
  final VoidCallback? onTap;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: TextButton.icon(
        onPressed: loading ? null : onTap,
        style: TextButton.styleFrom(
          foregroundColor: c.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: loading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.onSurfaceVariant,
                ),
              )
            : const Icon(Icons.account_circle_outlined, size: 18),
        label: Text(
          loading
              ? AppLocalizations.of(context).signingIn
              : AppLocalizations.of(context).signInWithGoogleRecover,
          style: GoogleFonts.nunito(
            fontSize: 13,
            color: c.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
