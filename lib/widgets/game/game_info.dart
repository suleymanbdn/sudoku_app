import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/difficulty_label.dart';
import '../../models/game_state.dart';
import '../../providers/ad_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/hint_coins_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../screens/unlock_pro_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/neon_chrome.dart';
import '../sudoku_brand_title.dart';

class AppBarTitle extends ConsumerWidget {
  const AppBarTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final difficulty = ref.watch(difficultyProvider);
    final status = ref.watch(gameStatusProvider);
    final duel = ref.watch(gameProvider.select((g) => g.isDuel));
    final isActive = status == GameStatus.playing ||
        status == GameStatus.paused ||
        status == GameStatus.generating;
    final c = context.appColors;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: c.container,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: c.primary.withValues(alpha: 0.3),
                ),
              ).withNeonIf(context, c),
              child: Text(
                difficulty.localizedLabel(context),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: c.dark,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            if (duel) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.primary.withValues(alpha: 0.45)),
                ).withNeonIf(context, c),
                child: Text(
                  AppLocalizations.of(context).duelLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: c.primary,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class SoundToggleButton extends ConsumerWidget {
  const SoundToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(soundEnabledProvider);
    return IconButton(
      icon: Icon(on ? Icons.volume_up_rounded : Icons.volume_off_rounded),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
      tooltip: on
          ? AppLocalizations.of(context).mute
          : AppLocalizations.of(context).unmute,
      onPressed: () => ref.read(soundEnabledProvider.notifier).toggle(),
    );
  }
}

class HintButton extends ConsumerStatefulWidget {
  const HintButton({super.key});

  @override
  ConsumerState<HintButton> createState() => _HintButtonState();
}

class _HintButtonState extends ConsumerState<HintButton> {
  bool _adLoading = false;
  bool _buyLoading = false;

  Future<void> _watchAdForHint() async {
    if (_adLoading) return;
    setState(() => _adLoading = true);
    try {
      final adService = ref.read(adServiceProvider);
      final earned = await adService.showRewardedAd();
      if (!mounted) return;
      if (earned) {
        ref.read(gameProvider.notifier)
          ..addHint()
          ..useHint();
      }
    } finally {
      if (mounted) setState(() => _adLoading = false);
    }
  }

  /// Uses one hint coin from the persistent pool, then applies it to the game.
  void _useCoinHint() {
    final used = ref.read(hintCoinsProvider.notifier).useOneCoin();
    if (used) {
      ref.read(gameProvider.notifier)
        ..addHint()
        ..useHint();
    }
  }

  Future<void> _buyHintPack() async {
    if (_buyLoading) return;
    setState(() => _buyLoading = true);
    try {
      final svc = ref.read(purchaseServiceProvider);
      final purchased = await svc.buyHintPack();
      // Coins are added via hintPackStream → hintCoinsProvider.
      // We do NOT apply a hint immediately here — the purchase stream is
      // async so coins haven't arrived yet, and applying addHint()/useHint()
      // before that would give a free hint on cancellations.
      // The user dismisses the sheet, sees their updated coin balance,
      // and uses a coin on the next tap.
      if (!purchased && mounted) {
        // Purchase was not initiated (store unavailable) — nothing to do.
        return;
      }
      // If purchased == true: coins arrive via stream shortly; UI updates automatically.
    } catch (_) {
      // User cancelled or store error — silently ignore.
    } finally {
      if (mounted) setState(() => _buyLoading = false);
    }
  }

  void _showGetMoreHintsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _GetMoreHintsSheet(
        onWatchAd: () {
          Navigator.pop(context);
          _watchAdForHint();
        },
        onUseCoin: () {
          Navigator.pop(context);
          _useCoinHint();
        },
        onBuyPack: () {
          Navigator.pop(context);
          _buyHintPack();
        },
        onGoPro: () {
          Navigator.pop(context);
          Navigator.of(context).push<bool>(UnlockProScreen.route()).then((_) {
            if (mounted) ref.invalidate(isProProvider);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hints = ref.watch(hintsRemainingProvider);
    final isPlaying = ref.watch(gameStatusProvider) == GameStatus.playing;
    final isPro = ref.watch(isProSyncProvider);
    final c = context.appColors;

    // ── Pro: unlimited hints (show ∞ badge, filled icon) ────────────────────
    if (isPro) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
            onPressed: isPlaying
                ? () => ref.read(gameProvider.notifier).useHint()
                : null,
            icon: Icon(
              Icons.lightbulb_rounded,
              color: isPlaying
                  ? c.primary
                  : c.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            tooltip: AppLocalizations.of(context).hintUnlimited,
          ),
          if (isPlaying)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: c.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '∞',
                    style: TextStyle(
                      color: c.pureWhite,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // ── Free + hints remaining: show count badge ─────────────────────────────
    if (hints > 0) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
            onPressed: isPlaying
                ? () => ref.read(gameProvider.notifier).useHint()
                : null,
            icon: Icon(
              Icons.lightbulb_outline_rounded,
              color: isPlaying
                  ? c.primary
                  : c.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            tooltip: AppLocalizations.of(context).hintLeft(hints),
          ),
          if (isPlaying)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: c.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$hints',
                    style: TextStyle(
                      color: c.pureWhite,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // ── Free + hints exhausted: show "get more hints" options ───────────────
    final busy = _adLoading || _buyLoading;
    return IconButton(
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
      onPressed: (isPlaying && !busy) ? _showGetMoreHintsSheet : null,
      tooltip: AppLocalizations.of(context).getMoreHints,
      icon: busy
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: c.primary,
              ),
            )
          : Icon(
              Icons.add_circle_outline_rounded,
              color: isPlaying
                  ? c.primary
                  : c.onSurfaceVariant.withValues(alpha: 0.4),
            ),
    );
  }
}

// ── "Get More Hints" bottom sheet ────────────────────────────────────────────

class _GetMoreHintsSheet extends ConsumerWidget {
  const _GetMoreHintsSheet({
    required this.onWatchAd,
    required this.onUseCoin,
    required this.onBuyPack,
    required this.onGoPro,
  });

  final VoidCallback onWatchAd;
  final VoidCallback onUseCoin;
  final VoidCallback onBuyPack;
  final VoidCallback onGoPro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final l = AppLocalizations.of(context);
    final coins = ref.watch(hintCoinsProvider);
    final packPrice =
        ref.watch(purchaseServiceProvider).hintPackPrice ?? '\$0.99';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: c.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l.getAHint,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: c.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l.getAHintSubtitle,
              style: TextStyle(
                fontSize: 14,
                color: c.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Watch ad
          _HintOption(
            icon: Icons.play_circle_outline_rounded,
            iconColor: Colors.green,
            title: l.watchShortAd,
            subtitle: l.watchShortAdSubtitle,
            onTap: onWatchAd,
          ),
          // Use coin
          if (coins > 0)
            _HintOption(
              icon: Icons.toll_rounded,
              iconColor: const Color(0xFFFFB300),
              title: l.useHintCoin,
              subtitle: l.hintCoinsYouHave(coins),
              onTap: onUseCoin,
            ),
          // Buy pack
          _HintOption(
            icon: Icons.shopping_bag_outlined,
            iconColor: c.primary,
            title: l.hintCoinsPack(packPrice),
            subtitle: l.hintCoinsPackSubtitle,
            onTap: onBuyPack,
          ),
          // Go Pro
          _HintOption(
            icon: Icons.all_inclusive_rounded,
            iconColor: const Color(0xFF9C27B0),
            title: l.unlockProUnlimitedHints,
            subtitle: l.unlockProUnlimitedHintsSubtitle,
            onTap: onGoPro,
            highlighted: true,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _HintOption extends StatelessWidget {
  const _HintOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: highlighted
            ? const Color(0xFF9C27B0).withValues(alpha: 0.08)
            : c.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: highlighted
                              ? const Color(0xFF9C27B0)
                              : c.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: c.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: c.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PauseButton extends ConsumerWidget {
  const PauseButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(gameStatusProvider);
    final isPaused = status == GameStatus.paused;
    final isActive =
        status == GameStatus.playing || status == GameStatus.paused;
    final c = context.appColors;

    return IconButton(
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
      onPressed: isActive
          ? () {
              isPaused
                  ? ref.read(gameProvider.notifier).resumeGame()
                  : ref.read(gameProvider.notifier).pauseGame();
            }
          : null,
      icon: Icon(
        isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
        color: isActive
            ? (c.isDark
                ? (Color.lerp(c.primary, Colors.white, 0.55) ?? c.primary)
                : c.primary)
            : c.onSurfaceVariant.withValues(alpha: 0.4),
      ),
      tooltip: isPaused
          ? AppLocalizations.of(context).resume
          : AppLocalizations.of(context).pause,
    );
  }
}

class GameInfoRow extends ConsumerWidget {
  const GameInfoRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elapsed = ref.watch(elapsedSecondsProvider);
    final mistakes = ref.watch(mistakeCountProvider);
    final difficulty = ref.watch(difficultyProvider);
    final progress = ref.watch(progressProvider);
    final status = ref.watch(gameStatusProvider);
    final isPaused = status == GameStatus.paused;

    final m = (elapsed ~/ 60).toString().padLeft(2, '0');
    final s = (elapsed % 60).toString().padLeft(2, '0');
    final timeStr = isPaused ? '--:--' : '$m:$s';
    final l = AppLocalizations.of(context);

    final narrow = MediaQuery.sizeOf(context).width < 380;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: narrow ? 10 : 24),
      child: Row(
        children: [
          Expanded(
            child: _InfoTile(
              icon: Icons.timer_outlined,
              value: timeStr,
              label: l.statTime,
            ),
          ),
          const _InfoDivider(),
          Expanded(
            child: _HeartsDisplay(
              mistakes: mistakes,
              maxMistakes: difficulty.maxMistakes,
            ),
          ),
          const _InfoDivider(),
          Expanded(
            child: _InfoTile(
              icon: Icons.check_circle_outline_rounded,
              value: '${(progress * 100).toInt()}%',
              label: l.complete,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartsDisplay extends StatefulWidget {
  const _HeartsDisplay({
    required this.mistakes,
    required this.maxMistakes,
  });

  final int mistakes;
  final int maxMistakes;

  @override
  State<_HeartsDisplay> createState() => _HeartsDisplayState();
}

class _HeartsDisplayState extends State<_HeartsDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  int get _remaining =>
      (widget.maxMistakes - widget.mistakes).clamp(0, widget.maxMistakes);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    if (_remaining == 1) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_HeartsDisplay old) {
    super.didUpdateWidget(old);
    final oldRemaining =
        (old.maxMistakes - old.mistakes).clamp(0, old.maxMistakes);
    if (oldRemaining != 1 && _remaining == 1) {
      _pulseCtrl.repeat(reverse: true);
    } else if (_remaining != 1 && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final remaining = _remaining;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.maxMistakes, (i) {
              final alive = i < remaining;
              final isLastHeart = alive && i == remaining - 1 && remaining == 1;
              final icon = Icon(
                alive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 18,
                color: alive
                    ? (remaining == 1
                        ? Colors.red.shade700
                        : Colors.red.shade500)
                    : c.outline,
              );
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: isLastHeart
                    ? AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (context, child) => Transform.scale(
                          scale: _pulseAnim.value,
                          child: child,
                        ),
                        child: icon,
                      )
                    : icon,
              );
            }),
          ),
          const SizedBox(height: 2),
          Text(
            AppLocalizations.of(context).lives,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: c.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _InfoTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.appColors;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: c.primary),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: c.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: c.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  const _InfoDivider();

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final o = c.outline;
    final midAlpha = c.isDark ? 0.85 : 1.0;
    return Container(
      width: 1,
      height: 38,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            o.withValues(alpha: 0.0),
            o.withValues(alpha: midAlpha),
            o.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}
