import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_bootstrap.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_update_provider.dart';
import 'providers/neon_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/update_available_screen.dart';
import 'services/sound_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_presets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/duel_provider.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Keep native splash visible until all async init is done
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // Sound init runs in background — doesn't block startup
  unawaited(SoundService.initAsync());

  await initializeFirebaseForApp();

  final prefs = await SharedPreferences.getInstance();
  await ensureDuelPlayerId(prefs);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // All init done — dismiss native splash
  FlutterNativeSplash.remove();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const SudokuApp(),
    ),
  );
}

class SudokuApp extends ConsumerWidget {
  const SudokuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeId = ref.watch(themeIdProvider);
    final brightness = ref.watch(brightnessProvider);
    final neonChrome = ref.watch(neonEffectsActiveProvider);
    final base = resolveAppColors(themeId, brightness);
    final colors = neonChrome
        ? applyNeonSkin(base, themeId: themeId, brightness: brightness)
        : base;
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData(
        colors,
        neonChromeEnabled: neonChrome,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _AppBootstrap(),
    );
  }
}

/// Checks Google Play for a newer version, then shows [UpdateAvailableScreen] when needed.
class _AppBootstrap extends ConsumerStatefulWidget {
  const _AppBootstrap();

  @override
  ConsumerState<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<_AppBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    final svc = ref.read(appUpdateServiceProvider);
    final info = await svc.fetchPlayUpdateInfo();
    if (!mounted || info == null || !svc.isUpdateAvailable(info)) return;
    final nav = Navigator.maybeOf(context);
    if (nav == null || !context.mounted) return;
    await nav.push<void>(
      PageRouteBuilder<void>(
        fullscreenDialog: true,
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: UpdateAvailableScreen(updateInfo: info),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const SudokuHomePage();
}
