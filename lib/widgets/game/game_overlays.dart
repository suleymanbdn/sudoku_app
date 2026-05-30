import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_localizations.dart';
import '../../models/game_state.dart';
import '../../providers/ad_provider.dart';
import '../../providers/daily_challenge_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/neon_chrome.dart';

class CelebrationOverlay extends ConsumerWidget {
  const CelebrationOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final size = MediaQuery.of(context).size;
    final c = context.appColors;
    final l = AppLocalizations.of(context);

    return Material(
      type: MaterialType.transparency,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xE8FFFFFF),
                c.celebrationMid,
                c.celebrationBottom.withValues(alpha: 0.96),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.45, 1.0],
            ),
          ).withNeonIf(context, c),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                const _SparkleRow(),
                const SizedBox(height: 28),
                const _TrophyBadge(),
                const SizedBox(height: 32),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: c.titleShaderColors,
                  ).createShader(bounds),
                  child: Text(
                    game.isDuel
                        ? l.celebrationDuelWin
                        : game.isDailyChallenge
                            ? l.celebrationDailyDone
                            : l.celebrationSolo,
                    style: GoogleFonts.dancingScript(
                      fontSize: 72,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (game.isDailyChallenge) ...[
                  _DailyStreakBadge(),
                  const SizedBox(height: 8),
                ] else
                  Text(
                    game.isDuel ? l.duelFinishedFirst : l.soloPerfect,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: c.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 32),
                _StatsCard(game: game),
                const SizedBox(height: 36),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ref.read(gameProvider.notifier).startGame(
                              game.difficulty,
                              isPro: ref.read(isProSyncProvider),
                            );
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      label: Text(
                        l.newGame,
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: c.pureWhite,
                        elevation: 4,
                        shadowColor: c.primary.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    l.mainMenu,
                    style: GoogleFonts.nunito(
                      color: c.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyStreakBadge extends ConsumerWidget {
  const _DailyStreakBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(dailyChallengeProvider).streak;
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: c.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(
            streak == 1
                ? AppLocalizations.of(context).streakStarted
                : AppLocalizations.of(context).streakDays(streak),
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: c.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SparkleRow extends StatefulWidget {
  const _SparkleRow();

  @override
  State<_SparkleRow> createState() => _SparkleRowState();
}

class _SparkleRowState extends State<_SparkleRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFFFD700);
    const sizes = [22.0, 30.0, 38.0, 30.0, 22.0];
    const offsets = [0.0, 200.0, 400.0, 600.0, 800.0];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = (_ctrl.value + offsets[i] / 1000) % 1.0;
            final scale = 0.8 + 0.35 * (0.5 - (t - 0.5).abs()) * 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Icon(
                  Icons.star_rounded,
                  color: goldColor,
                  size: sizes[i],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _TrophyBadge extends StatelessWidget {
  const _TrophyBadge();

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [c.container, c.pastel],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: c.primary, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: c.primary.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: -4,
          ),
        ],
      ).withNeonIf(context, c),
      child: Icon(
        Icons.emoji_events_rounded,
        size: 52,
        color: c.primary,
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final GameState game;
  const _StatsCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final hintCap = game.isDuel ? 0 : game.difficulty.soloHintsAllowed;
    final hintsUsed = hintCap - game.hintsRemaining;
    final perfectScore = game.mistakeCount == 0 && hintsUsed == 0;
    final c = context.appColors;
    final l = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: c.pureWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.outline),
        boxShadow: [
          BoxShadow(
            color: c.primary.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ).withNeonIf(context, c),
      child: Column(
        children: [
          if (perfectScore)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: const Color(0xFFFFD700), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.workspace_premium_rounded,
                        size: 16, color: Color(0xFFFF8F00)),
                    const SizedBox(width: 6),
                    Text(
                      l.perfectScore,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFF8F00),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.timer_outlined,
                  label: l.statTime,
                  value: game.formattedTime,
                  iconColor: c.primary,
                ),
                VerticalDivider(
                  color: c.outline,
                  width: 1,
                  thickness: 1,
                  indent: 4,
                  endIndent: 4,
                ),
                _StatItem(
                  icon: Icons.close_rounded,
                  label: l.statMistakes,
                  value: '${game.mistakeCount}',
                  iconColor: game.mistakeCount == 0
                      ? Colors.green.shade400
                      : Colors.red.shade400,
                  valueColor: game.mistakeCount == 0
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                ),
                VerticalDivider(
                  color: c.outline,
                  width: 1,
                  thickness: 1,
                  indent: 4,
                  endIndent: 4,
                ),
                _StatItem(
                  icon: Icons.lightbulb_outline_rounded,
                  label: l.statHints,
                  value: game.isDuel ? l.hintsOff : l.hintsUsed(hintsUsed),
                  iconColor: const Color(0xFFFFC107),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color? valueColor;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: valueColor ?? c.onSurface,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 11,
            color: c.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Full-screen 3…2…1 overlay before a online duel timer starts.
class DuelCountdownOverlay extends StatelessWidget {
  const DuelCountdownOverlay({super.key, required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: GoogleFonts.dancingScript(
                fontSize: 120,
                fontWeight: FontWeight.w700,
                color: c.pureWhite,
                height: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).getReady,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.pureWhite.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LostDialog extends ConsumerStatefulWidget {
  const LostDialog({super.key});

  @override
  ConsumerState<LostDialog> createState() => _LostDialogState();
}

class _LostDialogState extends ConsumerState<LostDialog> {
  bool _adLoading = false;

  /// Watch a rewarded ad → grant extra life → resume game.
  Future<void> _watchAdForExtraLife() async {
    if (_adLoading) return;
    setState(() => _adLoading = true);
    try {
      final adService = ref.read(adServiceProvider);
      final earned = await adService.showRewardedAd();
      if (!mounted) return;
      if (earned) {
        ref.read(gameProvider.notifier).grantExtraLife();
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).adNotAvailable),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _adLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    final theme = Theme.of(context);
    final c = context.appColors;
    final l = AppLocalizations.of(context);

    // Show the revive button only if: not a duel, and extra life hasn't been used yet.
    final canRevive = !game.isDuel && !game.extraLifeUsed;

    return Dialog(
      backgroundColor: c.pureWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.20),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.sentiment_dissatisfied_rounded,
                size: 44,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l.gameOver,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.red.shade500,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.lostMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: c.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _StatRowSimple(
              icon: Icons.close_rounded,
              label: l.statMistakes,
              value: '${game.mistakeCount} / ${game.difficulty.maxMistakes}',
              valueColor: Colors.red.shade600,
            ),
            const SizedBox(height: 20),

            // ── Revive via rewarded ad ──────────────────────────────────────
            if (canRevive) ...[
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.deepOrange.shade500],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _adLoading ? null : _watchAdForExtraLife,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 20),
                      child: _adLoading
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.play_circle_outline_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.watchAdContinue,
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      l.watchAdSubtitle,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: Colors.white.withValues(
                                            alpha: 0.85),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // ── Try Again ───────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(gameProvider.notifier).startGame(
                        game.difficulty,
                        isPro: ref.read(isProSyncProvider),
                      );
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l.tryAgain),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text(l.mainMenu),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRowSimple extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRowSimple({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.outline),
      ).withNeonIf(context, c),
      child: Row(
        children: [
          Icon(icon, size: 16, color: c.primary),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: valueColor ?? c.onSurface,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
