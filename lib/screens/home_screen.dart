import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import '../theme/theme_presets.dart';
import '../widgets/effects/ambient_background.dart';
import '../widgets/home_play_tab.dart';
import '../widgets/home_scores_tab.dart';
import '../widgets/home_settings_tab.dart';

class SudokuHomePage extends ConsumerStatefulWidget {
  const SudokuHomePage({super.key});

  @override
  ConsumerState<SudokuHomePage> createState() => _SudokuHomePageState();
}

class _SudokuHomePageState extends ConsumerState<SudokuHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final l = AppLocalizations.of(context);
    final dark = ref.watch(brightnessProvider) == AppBrightness.dark;
    final gameStatus = ref.watch(gameStatusProvider);

    if (gameStatus == GameStatus.generating) {
      return Scaffold(
        backgroundColor: c.surface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: c.primary),
              const SizedBox(height: 20),
              Text(
                l.preparingPuzzle,
                style: GoogleFonts.nunito(fontSize: 14, color: c.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.surface,
      body: AmbientBackground(
        colors: c,
        dark: dark,
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            const PlayTab(),
            ScoresTab(onPlayTap: () => setState(() => _selectedIndex = 0)),
            const SettingsTab(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.grid_on_outlined),
            selectedIcon: const Icon(Icons.grid_on_rounded),
            label: l.navPlay,
          ),
          NavigationDestination(
            icon: const Icon(Icons.emoji_events_outlined),
            selectedIcon: const Icon(Icons.emoji_events_rounded),
            label: l.navScores,
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune_outlined),
            selectedIcon: const Icon(Icons.tune_rounded),
            label: l.navSettings,
          ),
        ],
      ),
    );
  }
}
