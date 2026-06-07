import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game_logic/sudoku_engine.dart';
import '../l10n/app_localizations.dart';
import '../l10n/difficulty_label.dart';
import '../models/game_state.dart';
import '../providers/daily_challenge_provider.dart';
import '../providers/game_provider.dart';
import '../providers/purchase_provider.dart';
import '../screens/game_screen.dart';
import '../screens/unlock_pro_screen.dart';
import '../theme/app_colors.dart';
import '../screens/duel_lobby_screen.dart';
import 'effects/entrance.dart';
import 'sudoku_brand_title.dart';

class PlayTab extends ConsumerWidget {
  const PlayTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameStatus = ref.watch(gameStatusProvider);
    final hasActiveGame =
        gameStatus == GameStatus.playing || gameStatus == GameStatus.paused;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Entrance(delay: Duration(milliseconds: 40), child: _PlayHeader()),
              if (hasActiveGame) ...[
                const SizedBox(height: 20),
                const Entrance(
                    delay: Duration(milliseconds: 110), child: _ContinueCard()),
              ],
              const SizedBox(height: 20),
              const Entrance(
                  delay: Duration(milliseconds: 180),
                  child: _DailyChallengeCard()),
              const SizedBox(height: 16),
              const SizedBox(height: 12),
              const Entrance(
                  delay: Duration(milliseconds: 250),
                  child: _DifficultySection()),
              const SizedBox(height: 20),
              const Entrance(
                  delay: Duration(milliseconds: 320), child: _DuelRaceCard()),
              const SizedBox(height: 20),
              const Entrance(
                  delay: Duration(milliseconds: 390), child: _ProBanner()),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayHeader extends ConsumerWidget {
  const _PlayHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final isPro = ref.watch(isProSyncProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).whichDifficultyToday,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        if (isPro) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [c.primary, c.dark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: c.primary.withValues(alpha: 0.38),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              '⚡ ${AppLocalizations.of(context).proBadge}',
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ContinueCard extends ConsumerWidget {
  const _ContinueCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameStatus = ref.watch(gameStatusProvider);
    final hasActiveGame =
        gameStatus == GameStatus.playing || gameStatus == GameStatus.paused;
    if (!hasActiveGame) return const SizedBox.shrink();

    final progress = ref.watch(progressProvider);
    final difficulty = ref.watch(difficultyProvider);
    final theme = Theme.of(context);
    final c = context.appColors;
    final l = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(GameScreen.route()),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: c.isDark
                ? [Color.lerp(c.primary, c.surface, 0.72)!, Color.lerp(c.primaryLight, c.surface, 0.58)!]
                : [Color.lerp(c.container, c.pureWhite, 0.35)!, c.pureWhite],
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
                    l.continueGame,
                    style: theme.textTheme.titleSmall?.copyWith(
                      // In dark mode, primary often blends into the lightened
                      // secondaryContainer card BG. Lift contrast by mixing
                      // primary with white.
                      color: c.isDark
                          ? (Color.lerp(c.primary, Colors.white, 0.35) ??
                              c.primary)
                          : c.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.continueProgress(
                      difficulty.localizedLabel(context),
                      (progress * 100).toInt(),
                    ),
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

class _DifficultySection extends ConsumerWidget {
  const _DifficultySection();

  static List<_CardConfig> _configsFor(AppColors c, AppLocalizations l) => [
        _CardConfig(
          difficulty: Difficulty.easy,
          emoji: '🥉',
          title: l.difficultyEasy,
          subtitle: l.difficultyEasySubtitle,
          startColor: Color.lerp(c.primaryLight, c.surface, 0.52)!,
          endColor: Color.lerp(c.pastel, c.primaryLight, 0.45)!,
          accentColor: c.primaryLight,
          badgeText: l.badgeBronze,
        ),
        _CardConfig(
          difficulty: Difficulty.medium,
          emoji: '🥈',
          title: l.difficultyMedium,
          subtitle: l.difficultyMediumSubtitle,
          startColor: Color.lerp(c.primary, c.surface, 0.48)!,
          endColor: c.primaryLight,
          accentColor: c.primary,
          badgeText: l.badgeSilver,
        ),
        _CardConfig(
          difficulty: Difficulty.hard,
          emoji: '🥇',
          title: l.difficultyHard,
          subtitle: l.difficultyHardSubtitle,
          startColor: c.primaryLight,
          endColor: c.primary,
          accentColor: c.pureWhite,
          badgeText: l.badgeGold,
        ),
        _CardConfig(
          difficulty: Difficulty.expert,
          emoji: '💎',
          title: l.difficultyExpert,
          subtitle: l.difficultyExpertSubtitle,
          startColor: c.primary,
          endColor: Color.lerp(c.primary, c.dark, 0.55)!,
          accentColor: c.pureWhite,
          badgeText: l.badgeDiamond,
        ),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final l = AppLocalizations.of(context);
    final configs = _configsFor(c, l);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.startNewGame,
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

  // All difficulty levels are free — no paywall on difficulties.
  bool get _requiresPro => false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final isPro = ref.watch(isProSyncProvider);
    final locked = _requiresPro && !isPro;

    final textColor = _isDark ? Colors.white : c.onSurface;
    final subColor = _isDark ? Colors.white70 : c.onSurfaceVariant;

    return _PressScale(
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
          ref.read(gameProvider.notifier).startGame(
                config.difficulty,
                isPro: ref.read(isProSyncProvider),
              );
          if (context.mounted) Navigator.of(context).push(GameScreen.route());
        },
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 128,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [config.startColor, config.endColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: config.endColor.withValues(alpha: locked ? 0.18 : 0.40),
                blurRadius: locked ? 6 : 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                right: -20,
                top: -28,
                child: _DecorCircle(
                  size: 110,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              Positioned(
                right: 50,
                bottom: -34,
                child: _DecorCircle(
                  size: 88,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Row(
                  children: [
                    _TierOrb(
                      emoji: config.emoji,
                      startColor: config.startColor,
                      endColor: config.endColor,
                    ),
                    const SizedBox(width: 18),
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
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  config.badgeText,
                                  style: GoogleFonts.nunito(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            config.subtitle,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: subColor,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!locked)
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: _isDark
                              ? Colors.white.withValues(alpha: 0.85)
                              : c.dark,
                        ),
                      ),
                  ],
                ),
              ),
              // Locked overlay
              if (locked)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.32),
                            Colors.black.withValues(alpha: 0.16),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context).proBadge,
                                style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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

class _TierOrb extends StatelessWidget {
  const _TierOrb({
    required this.emoji,
    required this.startColor,
    required this.endColor,
  });

  final String emoji;
  final Color startColor;
  final Color endColor;
  static const double size = 60;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.28),
            Colors.white.withValues(alpha: 0.08),
          ],
          center: Alignment.topLeft,
          radius: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: endColor.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }
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
                  child:
                      Icon(Icons.flash_on_rounded, color: c.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _strutNunitoLine(
                        AppLocalizations.of(context).duelRace,
                        color: c.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(height: 2),
                      _strutNunitoLine(
                        AppLocalizations.of(context).duelRaceSubtitle,
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
}

class _DailyChallengeCard extends ConsumerWidget {
  const _DailyChallengeCard();

  String _fmtTime(int? s) {
    if (s == null) return '--:--';
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dc = ref.watch(dailyChallengeProvider);
    final c = context.appColors;
    final l = AppLocalizations.of(context);

    if (dc.completedToday) {
      // ---- Completed state ----
      final mistakes = dc.bestMistakes ?? 0;
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [c.container, c.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.primary.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: c.primary.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('✅', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.dailyCompleted,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: c.primary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_fmtTime(dc.bestTimeSeconds)}  ·  ${mistakes == 0 ? l.dailyPerfect : l.dailyMistakesCount(mistakes)}',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            _StreakBadge(streak: dc.streak),
          ],
        ),
      );
    }

    // ---- Not completed state ----
    const gradientStart = Color(0xFFFF6B35);
    const gradientEnd = Color(0xFFFF8E53);

    return GestureDetector(
      onTap: () {
        ref.read(gameProvider.notifier).startDailyChallenge(
              isPro: ref.read(isProSyncProvider),
            );
        Navigator.of(context).push(GameScreen.route());
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [gradientStart, gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientStart.withValues(alpha: 0.40),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🔥', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.dailyChallenge,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        dc.today,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      if (dc.streak > 0) ...[
                        const SizedBox(width: 8),
                        _StreakBadge(streak: dc.streak, light: true),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l.playButton,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: gradientStart,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak, this.light = false});
  final int streak;
  final bool light;

  @override
  Widget build(BuildContext context) {
    if (streak == 0) return const SizedBox.shrink();
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: light
            ? Colors.white.withValues(alpha: 0.22)
            : c.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '🔥 $streak',
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: light ? Colors.white : c.primary,
        ),
      ),
    );
  }
}

class _ProBanner extends ConsumerWidget {
  const _ProBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProSyncProvider);
    if (isPro) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);

    return _PressScale(
      child: GestureDetector(
      onTap: () async {
        final purchased =
            await Navigator.of(context).push<bool>(UnlockProScreen.route());
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
                    l.goProTitle,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    l.goProSubtitle,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l.buyButton,
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
      ),
    );
  }
}

/// Subtle press feedback — scales down to 0.97 while a pointer is held,
/// springing back on release. Uses [Listener] so it never competes with the
/// child's own tap gesture (InkWell / GestureDetector).
class _PressScale extends StatefulWidget {
  const _PressScale({required this.child});

  final Widget child;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
