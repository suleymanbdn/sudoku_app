import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_localizations.dart';
import '../../models/game_state.dart';
import '../../providers/game_provider.dart';
import '../../theme/app_colors.dart';

class NumPad extends ConsumerWidget {
  const NumPad({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(boardSnapshotProvider);
    final isPlaying = snap.status == GameStatus.playing;
    final noteMode = ref.watch(noteModeProvider);

    final boardReady = snap.currentBoard.length == 9 &&
        snap.status != GameStatus.generating;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(9, (i) {
              final num = i + 1;
              return Expanded(
                child: _DigitRemainingHint(
                  visible: boardReady,
                  remaining: boardReady ? snap.remainingForDigit(num) : 0,
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(9, (i) {
              final num = i + 1;
              final count = snap.countOnBoard(num);
              final isComplete = !noteMode && count >= 9;

              return Expanded(
                child: _NumButton(
                  number: num,
                  isComplete: isComplete,
                  isEnabled: isPlaying && !isComplete,
                  isNoteMode: noteMode,
                  onTap: () =>
                      ref.read(gameProvider.notifier).enterNumber(num),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionIconButton(
                icon: noteMode ? Icons.edit_rounded : Icons.edit_outlined,
                label: AppLocalizations.of(context).notesAction,
                isActive: noteMode,
                isEnabled: isPlaying,
                onTap: isPlaying
                    ? () => ref.read(gameProvider.notifier).toggleNoteMode()
                    : null,
              ),
              SizedBox(width: MediaQuery.sizeOf(context).width * 0.10),
              _ActionIconButton(
                icon: Icons.backspace_outlined,
                label: AppLocalizations.of(context).eraseAction,
                isActive: false,
                isEnabled: isPlaying,
                onTap: isPlaying
                    ? () =>
                        ref.read(gameProvider.notifier).clearSelectedCell()
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DigitRemainingHint extends StatelessWidget {
  const _DigitRemainingHint({
    required this.visible,
    required this.remaining,
  });

  final bool visible;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: SizedBox(
        height: 18,
        child: Center(
          child: !visible
              ? Text(
                  '·',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1,
                    fontWeight: FontWeight.w600,
                    color: c.outline.withValues(alpha: 0.35),
                  ),
                )
              : remaining == 0
                  ? Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: c.primary.withValues(alpha: 0.45),
                    )
                  : Text(
                      '$remaining',
                      style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: c.onSurfaceVariant,
                        letterSpacing: -0.2,
                      ),
                    ),
        ),
      ),
    );
  }
}

class _NumButton extends StatefulWidget {
  final int number;
  final bool isComplete;
  final bool isEnabled;
  final bool isNoteMode;
  final VoidCallback onTap;

  const _NumButton({
    required this.number,
    required this.isComplete,
    required this.isEnabled,
    required this.isNoteMode,
    required this.onTap,
  });

  @override
  State<_NumButton> createState() => _NumButtonState();
}

class _NumButtonState extends State<_NumButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_NumButton old) {
    super.didUpdateWidget(old);
    if (!old.isComplete && widget.isComplete) {
      _bounceCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: ScaleTransition(
        scale: _bounceAnim,
        child: Material(
          color: widget.isComplete
              ? c.primary.withValues(alpha: 0.08)
              : (widget.isEnabled
                  ? (c.isDark
                      ? Color.alphaBlend(
                          c.primary.withValues(alpha: 0.18), c.surface)
                      : c.container)
                  : c.outline.withValues(alpha: c.isDark ? 0.18 : 0.1)),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: widget.isEnabled ? widget.onTap : null,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.isEnabled
                      ? c.primary.withValues(alpha: c.isDark ? 0.5 : 0.10)
                      : Colors.transparent,
                ),
              ),
              child: Center(
                child: Text(
                  '${widget.number}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    // In dark mode, primary blended with white reads MUCH stronger
                    // against the lightened container background.
                    color: widget.isComplete
                        ? c.primary.withValues(alpha: c.isDark ? 0.55 : 0.3)
                        : (widget.isEnabled
                            ? (c.isDark
                                ? (Color.lerp(c.primary, Colors.white, 0.88) ??
                                    Colors.white)
                                : c.primary)
                            : (c.isDark
                                ? c.onSurface.withValues(alpha: 0.75)
                                : c.onSurfaceVariant.withValues(alpha: 0.5))),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isEnabled;
  final VoidCallback? onTap;

  const _ActionIconButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isEnabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final color = isEnabled
        ? (isActive ? c.primary : c.onSurfaceVariant)
        : c.onSurfaceVariant.withValues(alpha: 0.3);

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
