import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/game_provider.dart';
import '../../theme/app_colors.dart';

class CellFlashEvent {
  final int row, col, delayMs;
  final Color color;
  const CellFlashEvent({
    required this.row,
    required this.col,
    required this.delayMs,
    required this.color,
  });
}

class FlashBusScope extends InheritedWidget {
  final Stream<CellFlashEvent> stream;
  const FlashBusScope({required this.stream, required super.child});

  static Stream<CellFlashEvent>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FlashBusScope>()?.stream;

  @override
  bool updateShouldNotify(FlashBusScope old) => stream != old.stream;
}

class SudokuCell extends StatefulWidget {
  final int row;
  final int col;
  final BoardSnapshot snap;
  final VoidCallback onTap;

  const SudokuCell({
    super.key,
    required this.row,
    required this.col,
    required this.snap,
    required this.onTap,
  });

  @override
  State<SudokuCell> createState() => _SudokuCellState();
}

class _SudokuCellState extends State<SudokuCell>
    with TickerProviderStateMixin {
  late final AnimationController _flashCtrl;
  Color _flashColor = Colors.transparent;

  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  StreamSubscription<CellFlashEvent>? _flashSub;

  @override
  void initState() {
    super.initState();
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 580),
    );
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.22), weight: 38),
      TweenSequenceItem(tween: Tween(begin: 1.22, end: 1.0), weight: 62),
    ]).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut));

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_flashSub == null) {
      final stream = FlashBusScope.of(context);
      if (stream != null) {
        _flashSub = stream.listen(_onFlash);
      }
    }
  }

  void _onFlash(CellFlashEvent e) {
    if (e.row != widget.row || e.col != widget.col) return;
    Future.delayed(Duration(milliseconds: e.delayMs), () {
      if (!mounted) return;
      setState(() => _flashColor = e.color);
      _flashCtrl.forward(from: 0);
    });
  }

  @override
  void didUpdateWidget(SudokuCell old) {
    super.didUpdateWidget(old);
    if (old.snap.currentBoard.isNotEmpty &&
        widget.snap.currentBoard.isNotEmpty) {
      final oldVal = old.snap.currentBoard[widget.row][widget.col];
      final newVal = widget.snap.currentBoard[widget.row][widget.col];
      final isErr =
          widget.snap.errorCells.contains('${widget.row},${widget.col}');
      final wasErr =
          old.snap.errorCells.contains('${widget.row},${widget.col}');

      // Correct entry → scale pop
      if (oldVal == 0 && newVal != 0 && !isErr) {
        _scaleCtrl.forward(from: 0);
      }
      // New error → shake
      if (!wasErr && isErr) {
        _shakeCtrl.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _flashSub?.cancel();
    _flashCtrl.dispose();
    _scaleCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  bool get _isSelected =>
      widget.snap.selectedRow == widget.row &&
      widget.snap.selectedCol == widget.col;

  bool get _isFixed =>
      widget.snap.isFixed.isNotEmpty &&
      widget.snap.isFixed[widget.row][widget.col];

  bool get _isError =>
      widget.snap.errorCells.contains('${widget.row},${widget.col}');

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final val = widget.snap.currentBoard[widget.row][widget.col];
    final highlighted = widget.snap.highlightedCells.contains('${widget.row},${widget.col}');
    final sameDigit = widget.snap.sameDigitCells.contains('${widget.row},${widget.col}');
    final notes = widget.snap.notes[widget.row][widget.col];

    // Dark mode needs higher alpha — highlights barely visible on dark surfaces
    Color bgColor = Colors.transparent;
    if (_isSelected) {
      bgColor = c.primary.withValues(alpha: c.isDark ? 0.35 : 0.18);
    } else if (highlighted) {
      bgColor = c.primary.withValues(alpha: c.isDark ? 0.16 : 0.08);
    } else if (sameDigit) {
      bgColor = c.primary.withValues(alpha: c.isDark ? 0.26 : 0.12);
    }

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _flashCtrl,
        builder: (context, child) {
          // Ease-in then ease-out: peaks at t=0.2, fades to 0 at t=1.0
          final t = _flashCtrl.value;
          final envelope = t < 0.2
              ? t / 0.2
              : 1.0 - ((t - 0.2) / 0.8);
          final flashAlpha = envelope * 0.55;
          return Container(
            decoration: BoxDecoration(
              color: flashAlpha > 0.01
                  ? Color.alphaBlend(
                      _flashColor.withValues(alpha: flashAlpha),
                      bgColor,
                    )
                  : bgColor,
            ),
            child: child,
          );
        },
        child: Center(
          child: AnimatedBuilder(
            animation: _shakeAnim,
            builder: (context, child) => Transform.translate(
              offset: Offset(_shakeAnim.value, 0),
              child: child,
            ),
            child: ScaleTransition(
              scale: _scaleAnim,
              child: _buildCellContent(c, val, notes),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCellContent(AppColors c, int val, Set<int> notes) {
    if (val != 0) {
      return Text(
        '$val',
        style: GoogleFonts.nunito(
          fontSize: 24,
          fontWeight: _isFixed ? FontWeight.w900 : FontWeight.w700,
          color: _isError ? Colors.red : (_isFixed ? c.onSurface : c.primary),
        ),
      );
    }

    if (notes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(2),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(9, (i) {
          final digit = i + 1;
          final has = notes.contains(digit);
          return Center(
            child: Text(
              has ? '$digit' : '',
              style: GoogleFonts.nunito(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                // Was onSurfaceVariant.alpha(0.7) — too faded to read on most palettes.
                // Now: onSurface in dark, onSurfaceVariant in light (still clear).
                color: c.isDark
                    ? c.onSurface.withValues(alpha: 0.85)
                    : c.onSurfaceVariant.withValues(alpha: 0.85),
              ),
            ),
          );
        }),
      ),
    );
  }
}
