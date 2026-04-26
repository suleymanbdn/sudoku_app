import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_bootstrap.dart';
import 'game_logic/sudoku_engine.dart';
import 'models/game_state.dart';
import 'providers/app_update_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/duel_provider.dart';
import 'providers/game_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/duel_lobby_screen.dart';
import 'screens/game_screen.dart';
import 'screens/unlock_pro_screen.dart';
import 'screens/update_available_screen.dart';
import 'services/sound_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/theme_presets.dart';
import 'widgets/sudoku_brand_title.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sound init runs in background — doesn't block startup
  unawaited(SoundService.initAsync());

  await initializeFirebaseForApp();

  final prefs = await SharedPreferences.getInstance();
  await ensureDuelPlayerId(prefs);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFFFFFF),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

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
    final colors = appColorsFor(themeId);
    return MaterialApp(
      title: 'Sudoku Puzzle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData(colors),
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

class SudokuHomePage extends ConsumerWidget {
  const SudokuHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = context.appColors;
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
                'Preparing puzzle…',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: c.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        title: const SudokuBrandTitle(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const _HomeHeader(),
              const SizedBox(height: 24),
              const _ThemeSection(),
              const SizedBox(height: 28),
              const _DifficultySection(),
              const SizedBox(height: 20),
              const _ProBanner(),
              const SizedBox(height: 20),
              const _ContinueCard(),
              const SizedBox(height: 20),
              const _DuelRaceCard(),
              const SizedBox(height: 20),
              const _ScoreButton(),
              const SizedBox(height: 16),
              const _AccountCard(),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [c.primary, c.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: c.primary.withValues(alpha: 0.35),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(Icons.grid_on_rounded, color: c.pureWhite, size: 44),
        ),
        const SizedBox(height: 16),
        Text(
          'Hello! 👋',
          style: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: c.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Which difficulty will you try today?',
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: c.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}


class _ThemeSection extends ConsumerWidget {
  const _ThemeSection();

  static const double _tileHeight = 92;
  static const double _gap = 8;
  static const double _minTileWidth = 68;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeIdProvider);
    final c = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color theme',
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
                      preview: appColorsFor(id),
                      frame: c,
                      selected: current == id,
                      onTap: () =>
                          ref.read(themeIdProvider.notifier).setTheme(id),
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
    required this.onTap,
  });

  final AppThemeId id;
  final AppColors preview;
  final AppColors frame;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
          decoration: BoxDecoration(
            color: frame.pureWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? frame.primary : frame.outline,
              width: selected ? 2.2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: frame.shadow,
                blurRadius: selected ? 10 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 36,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [preview.primary, preview.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  id.label,
                  maxLines: 1,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: frame.onSurface,
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


class _DifficultySection extends ConsumerWidget {
  const _DifficultySection();

  static List<_CardConfig> _configsFor(AppColors c) => [
        _CardConfig(
          difficulty: Difficulty.easy,
          emoji: '🥉',
          title: 'Easy',
          subtitle: 'Warm up your mind',
          startColor: Color.lerp(c.surface, c.container, 0.65)!,
          endColor: Color.lerp(c.container, c.pastel, 0.55)!,
          accentColor: c.primaryLight,
          badgeText: 'Bronze',
        ),
        _CardConfig(
          difficulty: Difficulty.medium,
          emoji: '🥈',
          title: 'Medium',
          subtitle: 'Solid challenge',
          startColor: c.container,
          endColor: Color.lerp(c.primaryLight, c.container, 0.42)!,
          accentColor: c.primary,
          badgeText: 'Silver',
        ),
        _CardConfig(
          difficulty: Difficulty.hard,
          emoji: '🥇',
          title: 'Hard',
          subtitle: 'Sharp and demanding',
          startColor: c.primaryLight,
          endColor: c.primary,
          accentColor: c.pureWhite,
          badgeText: 'Gold',
        ),
        _CardConfig(
          difficulty: Difficulty.expert,
          emoji: '💎',
          title: 'Expert',
          subtitle: 'Ultra sparse · only for masters',
          startColor: c.primary,
          endColor: Color.lerp(c.primary, c.dark, 0.55)!,
          accentColor: c.pureWhite,
          badgeText: 'Diamond',
        ),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final configs = _configsFor(c);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Start New Game',
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: c.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(
          configs.length,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: i < configs.length - 1 ? 12 : 0),
            child: _DifficultyCard(config: configs[i]),
          ),
        ),
      ],
    );
  }
}

class _CardConfig {
  final Difficulty difficulty;
  final String emoji;
  final String title;
  final String subtitle;
  final Color startColor;
  final Color endColor;
  final Color accentColor;
  final String badgeText;

  const _CardConfig({
    required this.difficulty,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.startColor,
    required this.endColor,
    required this.accentColor,
    required this.badgeText,
  });
}

class _DifficultyCard extends ConsumerWidget {
  final _CardConfig config;

  const _DifficultyCard({required this.config});

  bool get _isDark =>
      config.difficulty == Difficulty.hard ||
      config.difficulty == Difficulty.expert;

  bool get _requiresPro =>
      config.difficulty == Difficulty.hard ||
      config.difficulty == Difficulty.expert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final isPro = ref.watch(isProSyncProvider);
    final locked = _requiresPro && !isPro;

    final textColor = _isDark ? c.pureWhite : c.onSurface;
    final subColor = _isDark
        ? c.pureWhite.withValues(alpha: 0.8)
        : c.onSurfaceVariant;

    return Opacity(
      opacity: locked ? 0.72 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (locked) {
              final purchased = await Navigator.of(context)
                  .push<bool>(UnlockProScreen.route());
              if (purchased == true && context.mounted) {
                ref.invalidate(isProProvider);
              }
              return;
            }
            ref.read(gameProvider.notifier).startGame(config.difficulty);
            if (context.mounted) Navigator.of(context).push(GameScreen.route());
          },
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [config.startColor, config.endColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: config.endColor.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  top: -22,
                  child: _DecorCircle(
                    size: 90,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                Positioned(
                  right: 40,
                  bottom: -28,
                  child: _DecorCircle(
                    size: 70,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Text(
                        config.emoji,
                        style: const TextStyle(fontSize: 36),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Text(
                                  config.title,
                                  style: GoogleFonts.nunito(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white
                                        .withValues(alpha: 0.25),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    config.badgeText,
                                    style: GoogleFonts.nunito(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              config.subtitle,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: subColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        locked
                            ? Icons.lock_rounded
                            : Icons.arrow_forward_ios_rounded,
                        size: locked ? 20 : 16,
                        color: _isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : c.primary.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _DecorCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

/// Nunito + scroll: Without a fixed strut, baseline metrics can "shimmer" at
/// subpixel y-positions (especially letters like u). [forceStrutHeight] locks
/// line height so glyphs don't appear to move while scrolling.
Widget _strutNunitoLine(
  String text, {
  required Color color,
  required double fontSize,
  required FontWeight fontWeight,
}) {
  final style = GoogleFonts.nunito(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: 1.0,
  );
  return Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: style,
    strutStyle: StrutStyle.fromTextStyle(
      style,
      height: 1.0,
      leading: 0,
      forceStrutHeight: true,
    ),
    textHeightBehavior: const TextHeightBehavior(
      applyHeightToFirstAscent: false,
      applyHeightToLastDescent: false,
    ),
  );
}

class _DuelRaceCard extends StatelessWidget {
  const _DuelRaceCard();

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const DuelLobbyScreen(),
          ),
        ),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(c.primary, c.pureWhite, 0.88)!,
                c.pureWhite,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.primary.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: c.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: RepaintBoundary(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.flash_on_rounded, color: c.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _strutNunitoLine(
                        'Duel race',
                        color: c.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(height: 2),
                      _strutNunitoLine(
                        'Same puzzle — first correct finish wins',
                        color: c.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: c.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueCard extends ConsumerWidget {
  const _ContinueCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameStatus = ref.watch(gameStatusProvider);
    final hasActiveGame = gameStatus == GameStatus.playing ||
        gameStatus == GameStatus.paused;
    if (!hasActiveGame) return const SizedBox.shrink();

    final progress = ref.watch(progressProvider);
    final difficulty = ref.watch(difficultyProvider);
    final theme = Theme.of(context);
    final c = context.appColors;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(GameScreen.route()),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.lerp(c.container, c.pureWhite, 0.35)!,
              c.pureWhite,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.outline),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.play_circle_outline_rounded,
                  color: c.primary, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Continue',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: c.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${difficulty.label} · ${(progress * 100).toInt()}% complete',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: c.outline,
                      valueColor: AlwaysStoppedAnimation<Color>(c.primary),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: c.primary),
          ],
        ),
      ),
    );
  }
}

class _ScoreButton extends ConsumerWidget {
  const _ScoreButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scores = ref.watch(scoreProvider);
    final totalWins = scores.length;
    final c = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showScoreSheet(context, ref),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    color: Color(0xFFFFB300), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My scores',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.onSurface,
                      ),
                    ),
                    Text(
                      totalWins == 0
                          ? 'No completed games yet'
                          : '$totalWins wins',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: c.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.primary),
            ],
          ),
        ),
      ),
    );
  }

  void _showScoreSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ScoreSheet(ref: ref),
    );
  }
}


class _ScoreSheet extends ConsumerWidget {
  final WidgetRef ref;
  const _ScoreSheet({required this.ref});

  static String _fmt(int? seconds) {
    if (seconds == null) return '--:--';
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef innerRef) {
    final notifier = innerRef.read(scoreProvider.notifier);
    final scores = innerRef.watch(scoreProvider);
    final totalWins = scores.length;
    final c = context.appColors;

    final rows = [
      _ScoreRow(
        emoji: '🥉',
        label: 'Easy',
        wins: notifier.totalWins(Difficulty.easy),
        best: _fmt(notifier.bestTime(Difficulty.easy)),
        color: c.primaryLight,
      ),
      _ScoreRow(
        emoji: '🥈',
        label: 'Medium',
        wins: notifier.totalWins(Difficulty.medium),
        best: _fmt(notifier.bestTime(Difficulty.medium)),
        color: c.primary,
      ),
      _ScoreRow(
        emoji: '🥇',
        label: 'Hard',
        wins: notifier.totalWins(Difficulty.hard),
        best: _fmt(notifier.bestTime(Difficulty.hard)),
        color: c.primary,
      ),
      _ScoreRow(
        emoji: '💎',
        label: 'Expert',
        wins: notifier.totalWins(Difficulty.expert),
        best: _fmt(notifier.bestTime(Difficulty.expert)),
        color: c.dark,
      ),
    ];

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: c.pureWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Text(
                'Best scores',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: c.onSurface,
                ),
              ),
            ],
          ),

          if (totalWins == 0) ...[
            const SizedBox(height: 32),
            const Text('🎮', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'No wins yet.',
              style: GoogleFonts.nunito(
                fontSize: 15,
                color: c.onSurfaceVariant,
              ),
            ),
            Text(
              'Win your first game to see it here! ✨',
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: c.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              '$totalWins total wins 🎉',
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: c.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    child: Text('Difficulty',
                        style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: c.onSurfaceVariant)),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text('Wins',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: c.onSurfaceVariant)),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text('Best',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: c.onSurfaceVariant)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...rows.map((r) => _ScoreRowWidget(row: r)),
          ],
        ],
      ),
    ),
  );
  }
}

class _ScoreRow {
  final String emoji;
  final String label;
  final int wins;
  final String best;
  final Color color;
  const _ScoreRow({
    required this.emoji,
    required this.label,
    required this.wins,
    required this.best,
    required this.color,
  });
}

class _ScoreRowWidget extends StatelessWidget {
  final _ScoreRow row;
  const _ScoreRowWidget({required this.row});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: row.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(row.emoji,
                  style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              row.label,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: c.onSurface,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: row.wins > 0
                      ? row.color.withValues(alpha: 0.12)
                      : c.softWhite,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${row.wins}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: row.wins > 0 ? row.color : c.outline,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              row.best,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: row.best == '--:--'
                    ? c.outline
                    : const Color(0xFFFFB300),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pro Banner
// ---------------------------------------------------------------------------

class _ProBanner extends ConsumerWidget {
  const _ProBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProSyncProvider);
    if (isPro) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () async {
        final purchased = await Navigator.of(context)
            .push<bool>(UnlockProScreen.route());
        if (purchased == true && context.mounted) {
          ref.invalidate(isProProvider);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF9C55F5)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.40),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PRO\'ya Geç',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Hard & Expert seviyelerin kilidini aç — tek seferlik ödeme',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Satın Al',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF6C63FF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Google Account Card
// ---------------------------------------------------------------------------

class _AccountCard extends ConsumerStatefulWidget {
  const _AccountCard();

  @override
  ConsumerState<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends ConsumerState<_AccountCard> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInWithGoogle();
      if (!mounted || user == null) return;

      final cloudPro = await authService.fetchProFromCloud();
      if (!mounted) return;

      if (cloudPro) {
        await ref.read(purchaseServiceProvider).initialize(force: true);
        ref.invalidate(isProProvider);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Premium başarıyla geri yüklendi!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google hesabı bağlandı: ${user.email}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış yap'),
        content: const Text(
            'Google hesabından çıkmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çıkış yap'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).signOut();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isLinked = ref.watch(isSignedInWithGoogleProvider);
    final email = ref.watch(googleEmailProvider);

    return Column(
      children: [
        if (!isLinked)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    'Hesabına giriş yapmadan verilerini kaybedebilirsin. '
                    'Google hesabınla kaydet, her cihazda erişebilelsin.',
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
        Ink(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                      isLinked ? 'Google Hesabı' : 'Hesabınla kaydet',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.onSurface,
                      ),
                    ),
                    Text(
                      isLinked
                          ? (email ?? 'Bağlandı')
                          : 'Premium\'u yeni cihazlarda kurtar',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: c.onSurfaceVariant,
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
                    'Çıkış',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: c.onSurfaceVariant,
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: _signIn,
                  child: Text(
                    'Bağla',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
