import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game_logic/sudoku_engine.dart';
import '../l10n/app_localizations.dart';
import '../l10n/difficulty_label.dart';
import '../providers/daily_challenge_provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_colors.dart';
import 'gradient_text.dart';

class ScoresTab extends ConsumerWidget {
  const ScoresTab({super.key, this.onPlayTap});

  final VoidCallback? onPlayTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final l = AppLocalizations.of(context);
    final scores = ref.watch(scoreProvider);
    final notifier = ref.read(scoreProvider.notifier);
    final totalWins = scores.length;
    final streak = ref.watch(dailyChallengeProvider).streak;

    final cards = [
      (
        emoji: '🥉',
        label: Difficulty.easy.localizedLabel(context),
        wins: notifier.totalWins(Difficulty.easy),
        best: _fmtTime(notifier.bestTime(Difficulty.easy)),
        color: c.primaryLight
      ),
      (
        emoji: '🥈',
        label: Difficulty.medium.localizedLabel(context),
        wins: notifier.totalWins(Difficulty.medium),
        best: _fmtTime(notifier.bestTime(Difficulty.medium)),
        color: c.primary
      ),
      (
        emoji: '🥇',
        label: Difficulty.hard.localizedLabel(context),
        wins: notifier.totalWins(Difficulty.hard),
        best: _fmtTime(notifier.bestTime(Difficulty.hard)),
        color: c.primary
      ),
      (
        emoji: '💎',
        label: Difficulty.expert.localizedLabel(context),
        wins: notifier.totalWins(Difficulty.expert),
        best: _fmtTime(notifier.bestTime(Difficulty.expert)),
        color: c.dark
      ),
    ];

    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: GradientText(
                  l.myScores,
                  colors: c.titleShaderColors,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 20),
              // Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [c.primary, c.dark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: c.primary.withValues(alpha: 0.38),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('🏆', style: TextStyle(fontSize: 30)),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$totalWins',
                            style: GoogleFonts.nunito(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            l.totalWins,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (streak > 0) ...[
                        Container(
                          width: 1,
                          height: 44,
                          color: Colors.white.withValues(alpha: 0.22),
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '$streak',
                              style: GoogleFonts.nunito(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              l.dayStreak,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ] else
                        Text(
                          '✦',
                          style: TextStyle(
                            fontSize: 32,
                            color: Colors.white.withValues(alpha: 0.20),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  l.byDifficulty,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (totalWins == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: c.container,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('🎮', style: TextStyle(fontSize: 38)),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          l.noWinsYet,
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: c.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.noWinsYetSubtitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: c.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        if (onPlayTap != null) ...[
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: onPlayTap,
                            icon: const Icon(Icons.grid_on_rounded, size: 18),
                            label: Text(l.playButton),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final card in cards)
                        _DiffStatCard(
                          emoji: card.emoji,
                          label: card.label,
                          wins: card.wins,
                          bestTime: card.best,
                          accentColor: card.color,
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtTime(int? s) {
    if (s == null) return '--:--';
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }
}

class _DiffStatCard extends StatelessWidget {
  const _DiffStatCard({
    required this.emoji,
    required this.label,
    required this.wins,
    required this.bestTime,
    required this.accentColor,
  });

  final String emoji;
  final String label;
  final int wins;
  final String bestTime;
  final Color accentColor;

  static const Color _goldColor = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final hasData = wins > 0;
    final dimColor = c.onSurfaceVariant.withValues(alpha: 0.35);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.container,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: hasData ? accentColor.withValues(alpha: 0.28) : c.outline,
          width: hasData ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: hasData ? accentColor.withValues(alpha: 0.10) : c.shadow,
            blurRadius: hasData ? 14 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji orb
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: hasData
                  ? accentColor.withValues(alpha: 0.12)
                  : c.onSurfaceVariant.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(height: 10),
          // Difficulty label
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: c.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          // Big wins number
          Text(
            hasData ? '$wins' : '–',
            style: GoogleFonts.nunito(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.0,
              color: hasData ? accentColor : dimColor,
            ),
          ),
          Text(
            hasData
                ? AppLocalizations.of(context).winsLabel
                : AppLocalizations.of(context).noWinsShort,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: hasData ? accentColor.withValues(alpha: 0.65) : dimColor,
            ),
          ),
          const SizedBox(height: 8),
          // Best time — gold accent
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 12,
                color: hasData ? _goldColor : dimColor,
              ),
              const SizedBox(width: 3),
              Text(
                bestTime,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: hasData ? _goldColor : dimColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
