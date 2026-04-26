import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/store_links.dart';
import '../providers/app_update_provider.dart';
import '../theme/app_colors.dart';

/// Shown when Google Play reports a newer version than the installed build.
class UpdateAvailableScreen extends ConsumerStatefulWidget {
  const UpdateAvailableScreen({super.key, required this.updateInfo});

  final AppUpdateInfo updateInfo;

  @override
  ConsumerState<UpdateAvailableScreen> createState() =>
      _UpdateAvailableScreenState();
}

class _UpdateAvailableScreenState extends ConsumerState<UpdateAvailableScreen> {
  bool _busy = false;

  Future<void> _openPlayStore() async {
    final market = playStoreMarketUri;
    final https = playStoreHttpsUri;
    try {
      if (await canLaunchUrl(market)) {
        await launchUrl(market, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    await launchUrl(https, mode: LaunchMode.externalApplication);
  }

  Future<void> _onUpdateNow() async {
    setState(() => _busy = true);
    final svc = ref.read(appUpdateServiceProvider);
    try {
      if (widget.updateInfo.immediateUpdateAllowed) {
        final result = await svc.performImmediateUpdate();
        if (!mounted) return;
        if (result == AppUpdateResult.inAppUpdateFailed ||
            result == AppUpdateResult.userDeniedUpdate) {
          await _openPlayStore();
        }
        return;
      }
      await _openPlayStore();
    } catch (_) {
      if (mounted) await _openPlayStore();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onLater() async {
    await ref.read(appUpdateServiceProvider).snoozePrompt();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final vc = widget.updateInfo.availableVersionCode;

    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: _busy ? null : _onLater,
                  icon: Icon(Icons.close_rounded, color: c.onSurfaceVariant),
                  tooltip: 'Later',
                ),
              ),
              const Spacer(flex: 1),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: c.container,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: c.shadow,
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.system_update_rounded,
                  size: 56,
                  color: c.primary,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Update available',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: c.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                vc != null
                    ? 'A newer version is ready on Google Play (build $vc). Update for the latest fixes and improvements.'
                    : 'A newer version is ready on Google Play. Update for the latest fixes and improvements.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  height: 1.45,
                  color: c.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _busy ? null : _onUpdateNow,
                  style: FilledButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: c.pureWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _busy
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: c.pureWhite,
                          ),
                        )
                      : Text(
                          'Update now',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _busy ? null : _onLater,
                child: Text(
                  'Not now',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    color: c.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
