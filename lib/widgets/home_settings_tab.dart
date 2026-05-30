import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/neon_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/unlock_pro_screen.dart';
import '../theme/app_colors.dart';
import '../theme/theme_presets.dart';
import '../user_facing_messages.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).settingsTitle,
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800, color: c.primary)),
        backgroundColor: c.pureWhite,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _AppearanceSection(),
              const SizedBox(height: 28),
              const _ThemeSection(),
              const SizedBox(height: 20),
              const _NeonEffectsSection(),
              const SizedBox(height: 28),
              // Google account card: Android only — iOS uses Apple Sign-In (Guideline 4.8)
              if (!Platform.isIOS) ...[
                const _AccountSectionLabel(),
                const SizedBox(height: 10),
                const AccountCard(),
                const SizedBox(height: 28),
              ],
              const _LegalSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final l = AppLocalizations.of(context);
    final mode = ref.watch(brightnessProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.appearance,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: c.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<AppBrightness>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment<AppBrightness>(
              value: AppBrightness.light,
              label: Text(l.appearanceLight),
            ),
            ButtonSegment<AppBrightness>(
              value: AppBrightness.dark,
              label: Text(l.appearanceDark),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (next) {
            ref.read(brightnessProvider.notifier).setBrightness(next.first);
          },
        ),
      ],
    );
  }
}

class _NeonEffectsSection extends ConsumerWidget {
  const _NeonEffectsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final l = AppLocalizations.of(context);
    final isPro = ref.watch(isProSyncProvider);
    final neonPref = ref.watch(neonEffectsNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.neonEffects,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: c.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: c.pureWhite,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: isPro
                ? null
                : () {
                    Navigator.of(context)
                        .push<bool>(UnlockProScreen.route())
                        .then((purchased) {
                      if (purchased == true) {
                        ref.invalidate(isProProvider);
                      }
                    });
                  },
            borderRadius: BorderRadius.circular(16),
            child: SwitchListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Row(
                children: [
                  Text(
                    l.glowAndHighlights,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      color: c.onSurface,
                    ),
                  ),
                  if (!isPro) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: c.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l.proBadge,
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: c.pureWhite,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                isPro ? l.neonEffectsOn : l.neonEffectsUnlock,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: c.onSurfaceVariant,
                ),
              ),
              value: isPro && neonPref,
              onChanged: isPro
                  ? (v) {
                      ref
                          .read(neonEffectsNotifierProvider.notifier)
                          .setEnabled(v);
                    }
                  : null,
              secondary: Icon(
                isPro
                    ? Icons.electric_bolt_rounded
                    : Icons.lock_outline_rounded,
                color: isPro ? c.primary : c.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountSectionLabel extends StatelessWidget {
  const _AccountSectionLabel();

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Text(
      AppLocalizations.of(context).account,
      style: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: c.onSurfaceVariant,
          letterSpacing: 0.5),
    );
  }
}

class _ThemeSection extends ConsumerWidget {
  const _ThemeSection();

  static const double _tileHeight = 116;
  static const double _gap = 10;
  static const double _minTileWidth = 72;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeIdProvider);
    final brightness = ref.watch(brightnessProvider);
    final neonChrome = ref.watch(neonEffectsActiveProvider);
    final c = context.appColors;

    final isPro = ref.watch(isProSyncProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).colorTheme,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: c.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            var cols = AppThemeId.values.length;
            while (cols > 2) {
              final w = (maxW - (cols - 1) * _gap) / cols;
              if (w >= _minTileWidth) break;
              cols--;
            }
            final tileW = (maxW - (cols - 1) * _gap) / cols;

            return Wrap(
              spacing: _gap,
              runSpacing: _gap,
              children: [
                for (final id in AppThemeId.values)
                  SizedBox(
                    width: tileW,
                    height: _tileHeight,
                    child: _ThemePresetTile(
                      id: id,
                      preview: neonChrome
                          ? applyNeonSkin(
                              resolveAppColors(id, brightness),
                              themeId: id,
                              brightness: brightness,
                            )
                          : resolveAppColors(id, brightness),
                      frame: c,
                      selected: current == id,
                      neonGlowActive: neonChrome,
                      locked: id == AppThemeId.neon && !isPro,
                      onTap: () {
                        if (id == AppThemeId.neon && !isPro) {
                          Navigator.of(context)
                              .push<bool>(UnlockProScreen.route())
                              .then((purchased) {
                            if (purchased == true) {
                              ref.invalidate(isProProvider);
                            }
                          });
                          return;
                        }
                        ref.read(themeIdProvider.notifier).setTheme(id);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ThemePresetTile extends StatelessWidget {
  const _ThemePresetTile({
    required this.id,
    required this.preview,
    required this.frame,
    required this.selected,
    required this.neonGlowActive,
    required this.locked,
    required this.onTap,
  });

  final AppThemeId id;
  final AppColors preview;
  final AppColors frame;
  final bool selected;
  final bool neonGlowActive;
  final bool locked;
  final VoidCallback onTap;

  static const Color _neonCyan = Color(0xFF00E5FF);

  @override
  Widget build(BuildContext context) {
    final isNeon = id == AppThemeId.neon;

    final List<BoxShadow> shadow;
    if (selected && (isNeon || neonGlowActive)) {
      shadow = [
        BoxShadow(
          color: _neonCyan.withValues(alpha: 0.55),
          blurRadius: 16,
          spreadRadius: 1,
        ),
      ];
    } else if (selected) {
      shadow = [
        BoxShadow(
          color: preview.primary.withValues(alpha: 0.40),
          blurRadius: 14,
          spreadRadius: 1,
        ),
      ];
    } else {
      shadow = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.07),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(
                    preview.primary.withValues(alpha: 0.08), preview.surface)
                : preview.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? preview.primary
                  : preview.onSurface.withValues(alpha: 0.10),
              width: selected ? 2.0 : 1.0,
            ),
            boxShadow: shadow,
          ),
          child: Stack(
            children: [
              // Main content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  // Gradient circle with pastel accent dot
                  Center(
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: Stack(
                        children: [
                          // Main gradient circle
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [preview.primary, preview.primaryLight],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: preview.primary
                                      .withValues(alpha: preview.isDark ? 0.28 : 0.18),
                                  blurRadius: preview.isDark ? 8 : 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          // Pastel accent dot (bottom-right)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: preview.pastel,
                                border: Border.all(
                                  color: preview.surface,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          // Check icon for selected (non-locked)
                          if (selected && !locked)
                            Center(
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.90),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 15,
                                  color: preview.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Name + optional PRO badge
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      children: [
                        Text(
                          id.label,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                            color: preview.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        if (isNeon && !locked) ...[
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_neonCyan, Color(0xFF7C4DFF)],
                              ),
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: neonGlowActive
                                  ? [
                                      BoxShadow(
                                        color: _neonCyan.withValues(alpha: 0.55),
                                        blurRadius: 6,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Text(
                              AppLocalizations.of(context).proBadge,
                              style: const TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
              // Locked overlay — heavily mute the card so it doesn't look active
              if (locked)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ColoredBox(
                      color: preview.surface.withValues(alpha: 0.82),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: preview.onSurface.withValues(alpha: 0.10),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: preview.onSurfaceVariant
                                      .withValues(alpha: 0.30),
                                ),
                              ),
                              child: Icon(
                                Icons.lock_rounded,
                                size: 15,
                                color: preview.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Legal links ──────────────────────────────────────────────────────────────

class _LegalSection extends StatelessWidget {
  const _LegalSection();

  static const _privacyUrl =
      'https://suleymanbdn.github.io/sudoku/privacy-policy.html';
  static const _termsUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () => _launch(_privacyUrl),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            AppLocalizations.of(context).privacyPolicy,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: c.onSurfaceVariant,
              decoration: TextDecoration.underline,
              decorationColor: c.onSurfaceVariant,
            ),
          ),
        ),
        Text('·', style: TextStyle(color: c.onSurfaceVariant)),
        TextButton(
          onPressed: () => _launch(_termsUrl),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            AppLocalizations.of(context).termsOfUse,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: c.onSurfaceVariant,
              decoration: TextDecoration.underline,
              decorationColor: c.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class AccountCard extends ConsumerStatefulWidget {
  const AccountCard({super.key});

  @override
  ConsumerState<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends ConsumerState<AccountCard> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInWithGoogle();
      if (!mounted) return;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).googleSignInCouldNotFinish,
              style: GoogleFonts.nunito(),
            ),
          ),
        );
        return;
      }

      ref.invalidate(authStateProvider);

      final purchaseService = ref.read(purchaseServiceProvider);
      await purchaseService.loginUser(user.uid);
      if (!mounted) return;

      if (purchaseService.isPro) {
        ref.invalidate(isProProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).premiumRestored),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)
                  .googleAccountLinked(user.email ?? user.uid),
              style: GoogleFonts.nunito(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              googleSignInErrorForUser(AppLocalizations.of(context), e),
              style: GoogleFonts.nunito(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    final l = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.signOut),
        content: Text(l.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.signOut),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).signOut();
      await ref.read(purchaseServiceProvider).logoutUser();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final l = AppLocalizations.of(context);
    final isLinked = ref.watch(isSignedInWithGoogleProvider);
    final email = ref.watch(googleEmailProvider);

    final cardBody = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isLinked
                  ? Icons.account_circle_rounded
                  : Icons.account_circle_outlined,
              color: c.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLinked ? l.googleAccount : l.saveWithAccount,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.onSurface,
                  ),
                ),
                Text(
                  isLinked ? (email ?? l.connected) : l.recoverPremium,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: c.onSurfaceVariant,
                  ),
                ),
                if (!isLinked)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      l.tapToLink,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.primary.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_loading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: c.primary,
              ),
            )
          else if (isLinked)
            TextButton(
              onPressed: _signOut,
              child: Text(
                l.signOut,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: c.onSurfaceVariant,
                ),
              ),
            )
          else
            Text(
              l.linkButton,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: c.primary,
              ),
            ),
        ],
      ),
    );

    final decoratedCard = Container(
      decoration: BoxDecoration(
        color: c.pureWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.outline),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: isLinked
            ? cardBody
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _loading ? null : _signIn,
                  child: cardBody,
                ),
              ),
      ),
    );

    return Column(
      children: [
        if (!isLinked)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFD54F)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFF9A825), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.accountWarning,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7A5800),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        decoratedCard,
      ],
    );
  }
}
