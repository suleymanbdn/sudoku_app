import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../providers/purchase_provider.dart';
import '../services/purchase_service.dart';
import '../theme/app_colors.dart';

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
  String? _errorMessage;

  Future<void> _buy() async {
    final service = ref.read(purchaseServiceProvider);

    if (!service.canPurchase) {
      setState(() => _errorMessage =
          'Store unavailable right now. Please try again.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await service.buyPro();

      // Satın alma akışından onay gelene kadar bekle (max 60 sn).
      final confirmed = await service.purchaseStream
          .where((isPro) => isPro)
          .first
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () => false,
          );

      if (!mounted) return;
      if (confirmed) {
        Navigator.of(context).pop(true);
      } else {
        setState(
          () => _errorMessage =
              'Purchase could not be confirmed. Please try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Purchase failed. Please try again.',
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
      if (user == null) return; // kullanıcı iptal etti

      // Firestore'da kayıtlı pro var mı kontrol et
      final cloudPro = await authService.fetchProFromCloud();
      if (!mounted) return;

      if (cloudPro) {
        // Pro bulundu → local cache güncelle ve ekranı kapat
        final purchaseService = ref.read(purchaseServiceProvider);
        await purchaseService.initialize(force: true);
        ref.invalidate(isProProvider);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        setState(
          () => _errorMessage =
              'Google account linked. No previous purchase found.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Google sign-in failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
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
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await service.restorePurchases();
      final confirmed = await service.purchaseStream
          .where((isPro) => isPro)
          .first
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => false,
          );
      if (!mounted) return;
      if (confirmed) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _errorMessage = 'No previous purchase found.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Restore failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final priceAsync = ref.watch(productPriceProvider);
    final isGoogleLinked = ref.watch(isSignedInWithGoogleProvider);

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
                'Unlock Pro',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: c.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'One-time payment — no subscription, no ads.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  color: c.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              _FeatureRow(
                icon: Icons.psychology_rounded,
                label: 'Hard difficulty',
                c: c,
              ),
              const SizedBox(height: 12),
              _FeatureRow(
                icon: Icons.auto_awesome_rounded,
                label: 'Expert difficulty',
                c: c,
              ),
              const SizedBox(height: 12),
              _FeatureRow(
                icon: Icons.all_inclusive_rounded,
                label: 'All future difficulty levels',
                c: c,
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
                      errorDetail: service.lastError,
                    );
                  }
                  return _BuyButton(
                    label: 'Unlock for $price',
                    loading: _loading,
                    onTap: _buy,
                    c: c,
                  );
                },
                loading: () => _BuyButton(
                  label: 'Loading price…',
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
                    errorDetail: e.toString(),
                  );
                },
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: _loading ? null : _restore,
                child: Text(
                  'Restore purchase',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: c.onSurfaceVariant,
                    decoration: TextDecoration.underline,
                    decorationColor: c.onSurfaceVariant,
                  ),
                ),
              ),
              if (!isGoogleLinked) ...[
                const SizedBox(height: 4),
                _GoogleSignInButton(
                  loading: _googleLoading,
                  onTap: (_loading || _googleLoading) ? null : _signInWithGoogle,
                  c: c,
                ),
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
  });

  final IconData icon;
  final String label;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: c.primary),
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
    this.errorDetail,
  });

  final bool retrying;
  final VoidCallback onRetry;
  final AppColors c;
  final StoreStatus storeStatus;
  final String? errorDetail;

  String get _message {
    switch (storeStatus) {
      case StoreStatus.storeUnavailable:
        return 'Could not connect to Play Store.\nCheck your internet connection.';
      case StoreStatus.productNotFound:
        return 'Product not found in Play Console.\nEnsure the product ID is "unlock_full_game" and its status is Active.';
      case StoreStatus.queryError:
        return 'Play Store query error.\nMake sure the app was installed from the Play Store.';
      default:
        return 'Could not load product info.\nEnsure you installed the app via Google Play.';
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      _message,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    if (errorDetail != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        errorDetail!,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ],
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
              retrying ? 'Loading…' : 'Try Again',
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
              ? 'Signing in…'
              : 'Sign in with Google to restore Pro',
          style: GoogleFonts.nunito(
            fontSize: 13,
            color: c.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
