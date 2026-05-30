import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/game_state.dart';
import '../../providers/game_provider.dart';
import '../../providers/neon_provider.dart';
import '../../theme/app_colors.dart';
import 'sudoku_cell.dart';

class SudokuGridSection extends ConsumerWidget {
  const SudokuGridSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(gameStatusProvider);
    final c = context.appColors;
    final neon = ref.watch(neonEffectsActiveProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Stack(
          children: [
            const _SudokuGridCells(),
            IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: _GridLinePainter(
                  outline: c.outline,
                  primary: c.primary,
                  tertiary: c.tertiary,
                  neon: neon,
                  isDark: c.isDark,
                ),
              ),
            ),
            if (status == GameStatus.paused) const _PauseOverlay(),
            if (status == GameStatus.generating) const _LoadingOverlay(),
          ],
        ),
      ),
    );
  }
}

class _SudokuGridCells extends ConsumerWidget {
  const _SudokuGridCells();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(boardSnapshotProvider);

    if (snap.currentBoard.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 9,
        childAspectRatio: 1,
      ),
      itemCount: 81,
      itemBuilder: (_, index) {
        final row = index ~/ 9;
        final col = index % 9;
        return SudokuCell(
          row: row,
          col: col,
          snap: snap,
          onTap: () => ref.read(gameProvider.notifier).selectCell(row, col),
        );
      },
    );
  }
}

class _GridLinePainter extends CustomPainter {
  final Color outline;
  final Color primary;
  final Color tertiary;
  final bool neon;
  final bool isDark;

  _GridLinePainter({
    required this.outline,
    required this.primary,
    required this.tertiary,
    required this.neon,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Thin cell dividers — subtle
    final thinPaint = Paint()
      ..color = isDark
          ? outline.withValues(alpha: 0.65)
          : outline.withValues(alpha: 0.85)
      ..strokeWidth = 0.8;

    // Thick 3×3 box dividers — clearly visible, primary-tinted
    final boxColor = isDark
        ? Color.alphaBlend(primary.withValues(alpha: 0.55), outline)
        : outline;
    final thickPaint = Paint()
      ..color = boxColor
      ..strokeWidth = isDark ? 2.0 : 2.5;

    final step = size.width / 9;

    for (int i = 0; i <= 9; i++) {
      final isBox = i % 3 == 0;
      final p = isBox ? thickPaint : thinPaint;
      canvas.drawLine(Offset(i * step, 0), Offset(i * step, size.height), p);
      canvas.drawLine(Offset(0, i * step), Offset(size.width, i * step), p);
    }
  }

  @override
  bool shouldRepaint(_GridLinePainter old) =>
      outline != old.outline || neon != old.neon || isDark != old.isDark;
}

class _PauseOverlay extends ConsumerWidget {
  const _PauseOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    return GestureDetector(
      onTap: () => ref.read(gameProvider.notifier).resumeGame(),
      child: Container(
        color: c.surface.withValues(alpha: 0.9),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_circle_filled_rounded, size: 64, color: c.primary),
              const SizedBox(height: 12),
              Text(
                'Paused',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: c.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap to resume',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      color: c.surface.withValues(alpha: 0.8),
      child: Center(
        child: CircularProgressIndicator(color: c.primary),
      ),
    );
  }
}
