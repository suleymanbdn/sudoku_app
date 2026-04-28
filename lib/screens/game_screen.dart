import 'dart:async';
import 'dart:math' show pi;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/game_state.dart';
import '../providers/duel_provider.dart';
import '../providers/game_provider.dart';
import '../services/sound_service.dart';
import '../theme/app_colors.dart';
import '../widgets/sudoku_brand_title.dart';

// ---------------------------------------------------------------------------
// Cell flash bus — broadcast stream shared by all _SudokuCellState instances.
// ---------------------------------------------------------------------------

class _CellFlashEvent {
  final int row, col, delayMs;
  final Color color;
  const _CellFlashEvent({
    required this.row,
    required this.col,
    required this.delayMs,
    required this.color,
  });
}

final _flashBus = StreamController<_CellFlashEvent>.broadcast();

List<(int, int)> _cellsForGroup(String group) {
  if (group.startsWith('r')) {
    final r = int.parse(group.substring(1));
    return [for (int c = 0; c < 9; c++) (r, c)];
  } else if (group.startsWith('c')) {
    final c = int.parse(group.substring(1));
    return [for (int r = 0; r < 9; r++) (r, c)];
  } else {
    // 'b01' → br=0, bc=1  (box row, box col)
    final br = int.parse(group[1]) * 3;
    final bc = int.parse(group[2]) * 3;
    return [
      for (int r = br; r < br + 3; r++)
        for (int c = bc; c < bc + 3; c++) (r, c),
    ];
  }
}

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const GameScreen());

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final ConfettiController _confettiLeft;
  late final ConfettiController _confettiRight;
  bool _duelRaceOutcomeShown = false;

  bool _countdownActive = false;
  int _countdownValue = 3;
  bool _countdownStarted = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _confettiLeft =
        ConfettiController(duration: const Duration(seconds: 7));
    _confettiRight =
        ConfettiController(duration: const Duration(seconds: 7));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final game = ref.read(gameProvider);
      if (game.isDuel &&
          ref.read(gameStatusProvider) == GameStatus.playing &&
          !_countdownStarted) {
        _countdownStarted = true;
        _startCountdown();
      }
    });
  }

  @override
  void dispose() {
    _confettiLeft.dispose();
    _confettiRight.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }


  void _celebrate() {
    SoundService.playWin();
    _confettiLeft.play();
    _confettiRight.play();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showCelebrationOverlay();
    });
  }

  void _showCelebrationOverlay() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 750),
      transitionBuilder: (ctx, anim, _, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        final springy =
            CurvedAnimation(parent: anim, curve: Curves.elasticOut);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale:
                Tween<double>(begin: 0.82, end: 1.0).animate(springy),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) => const _CelebrationOverlay(),
    );
  }


  void _startCountdown() {
    setState(() {
      _countdownActive = true;
      _countdownValue = 3;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _countdownValue--);
      if (_countdownValue < 0) {
        t.cancel();
        setState(() => _countdownActive = false);
      }
    });
  }

  void _showLostDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LostDialog(),
    );
  }

  void _showDuelRaceResult({
    required bool tie,
    required bool won,
    bool opponentForfeit = false,
  }) {
    final c = context.appColors;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          tie
              ? 'Dead heat!'
              : won
                  ? 'You won the race!'
                  : 'They finished first',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
        ),
        content: Text(
          tie
              ? 'Same server finish time — call it a draw.'
              : won
                  ? opponentForfeit
                      ? 'Your opponent ran out of mistakes — you win!'
                      : 'You completed the grid first with a correct solution.'
                  : 'Your opponent reached the finish first this round.',
          style: GoogleFonts.nunito(
            fontSize: 14,
            height: 1.35,
            color: c.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duelRoomCode =
        ref.watch(gameProvider.select((g) => g.duelRoomCode ?? ''));

    ref.listen<AsyncValue<DocumentSnapshot<Map<String, dynamic>>?>>(
      duelRoomDocStreamProvider(duelRoomCode),
      (prev, next) {
        next.whenData((snap) {
          final gameNow = ref.read(gameProvider);
          if (!gameNow.isDuel || duelRoomCode.isEmpty) return;
          if (!ref.read(duelFirebaseReadyProvider)) return;
          if (snap == null || !snap.exists) return;
          final d = snap.data();
          if (d == null) return;
          if (_duelRaceOutcomeShown) return;

          final opponentForfeit = gameNow.duelIsHost
              ? d['guestForfeit'] == true
              : d['hostForfeit'] == true;
          final myForfeit = gameNow.duelIsHost
              ? d['hostForfeit'] == true
              : d['guestForfeit'] == true;

          if (opponentForfeit && !myForfeit) {
            _duelRaceOutcomeShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _showDuelRaceResult(
                  tie: false, won: true, opponentForfeit: true);
            });
            return;
          }

          final hostDone = d['hostDone'];
          final guestDone = d['guestDone'];
          if (hostDone is! Timestamp || guestDone is! Timestamp) return;
          _duelRaceOutcomeShown = true;
          final cmp = hostDone.compareTo(guestDone);
          final tie = cmp == 0;
          final won =
              tie ? false : (gameNow.duelIsHost ? cmp < 0 : cmp > 0);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showDuelRaceResult(tie: tie, won: won);
          });
        });
      },
    );

    // Sound: correct placement & errors
    ref.listen<GameState>(gameProvider, (prev, next) {
      if (prev == null) return;
      // Only trigger sounds during active play — not on game start/reset
      if (prev.status != GameStatus.playing) return;
      if (next.status != GameStatus.playing) return;
      if (next.currentBoard.isEmpty || prev.currentBoard.isEmpty) return;

      // Error placed
      if (next.errorCells.length > prev.errorCells.length) {
        SoundService.playError();
        return;
      }
      // Correct digit placed (0 → non-zero, no error)
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (prev.currentBoard[r][c] == 0 &&
              next.currentBoard[r][c] != 0 &&
              !next.errorCells.contains('$r,$c')) {
            SoundService.playPlace();
            return;
          }
        }
      }
    });

    // Sound + flash wave: row / column / box completed
    ref.listen<Set<String>>(completedGroupsProvider, (prev, next) {
      if (prev == null) return;
      final newGroups = next.difference(prev);
      if (newGroups.isEmpty) return;

      final hasBox = newGroups.any((g) => g.startsWith('b'));
      if (hasBox) {
        SoundService.playBox();
      } else {
        SoundService.playLine();
      }

      // Fire staggered flash events for each completed group
      for (final group in newGroups) {
        final cells = _cellsForGroup(group);
        final color = group.startsWith('b')
            ? const Color(0xFFBA68C8) // purple for box
            : const Color(0xFFFFB300); // gold for row / col
        for (int i = 0; i < cells.length; i++) {
          _flashBus.add(_CellFlashEvent(
            row: cells[i].$1,
            col: cells[i].$2,
            delayMs: i * 38,
            color: color,
          ));
        }
      }
    });

    ref.listen<GameStatus>(gameStatusProvider, (prev, next) {
      if (prev == next) return;
      if (prev == GameStatus.generating && next == GameStatus.playing) {
        final game = ref.read(gameProvider);
        if (game.isDuel && !_countdownStarted) {
          _countdownStarted = true;
          _startCountdown();
        }
      }
      if (next == GameStatus.won) {
        final game = ref.read(gameProvider);
        if (game.isDuel && game.duelRoomCode != null) {
          final fs = ref.read(duelFirestoreServiceProvider);
          if (fs.isReady) {
            unawaited(
              fs.reportFinish(
                roomCode: game.duelRoomCode!,
                isHost: game.duelIsHost,
              ),
            );
          }
        }
        unawaited(
          ref.read(scoreProvider.notifier).recordWin(
                game.difficulty,
                game.elapsedSeconds,
                game.mistakeCount,
              ),
        );
        _celebrate();
      } else if (next == GameStatus.lost) {
        final game = ref.read(gameProvider);
        if (game.isDuel && game.duelRoomCode != null) {
          final fs = ref.read(duelFirestoreServiceProvider);
          if (fs.isReady) {
            unawaited(
              fs.reportForfeit(
                roomCode: game.duelRoomCode!,
                isHost: game.duelIsHost,
              ),
            );
          }
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showLostDialog();
        });
      }
    });

    final c = context.appColors;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: c.surface,
          appBar: AppBar(
            centerTitle: false,
            titleSpacing: 12,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const _AppBarTitle(),
            actions: const [
              _SoundToggleButton(),
              SizedBox(width: 2),
              _HintButton(),
              SizedBox(width: 2),
              _PauseButton(),
              SizedBox(width: 4),
            ],
          ),
          body: const SafeArea(
            child: Column(
              children: [
                SizedBox(height: 10),
                _GameInfoRow(),
                SizedBox(height: 10),
                Expanded(
                  child: Center(child: _SudokuGridSection()),
                ),
                SizedBox(height: 10),
                _NumPad(),
                SizedBox(height: 14),
              ],
            ),
          ),
        ),

        _ConfettiCannon(
          controller: _confettiLeft,
          alignment: Alignment.topLeft,
          blastDirection: pi / 2.6,
        ),
        _ConfettiCannon(
          controller: _confettiRight,
          alignment: Alignment.topRight,
          blastDirection: pi - pi / 2.6,
        ),
        if (_countdownActive)
          _DuelCountdownOverlay(value: _countdownValue),
      ],
    );
  }
}


class _AppBarTitle extends ConsumerWidget {
  const _AppBarTitle();

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
          const SudokuBrandTitle(),
          if (isActive) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: c.container,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: c.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                difficulty.label,
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
                ),
                child: Text(
                  'DUEL',
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


class _SoundToggleButton extends ConsumerWidget {
  const _SoundToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(soundEnabledProvider);
    return IconButton(
      icon: Icon(on ? Icons.volume_up_rounded : Icons.volume_off_rounded),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
      tooltip: on ? 'Sesi kapat' : 'Sesi aç',
      onPressed: () => ref.read(soundEnabledProvider.notifier).toggle(),
    );
  }
}


class _HintButton extends ConsumerWidget {
  const _HintButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hints = ref.watch(hintsRemainingProvider);
    final isPlaying = ref.watch(gameStatusProvider) == GameStatus.playing;
    final c = context.appColors;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          padding: EdgeInsets.zero,
          onPressed: (isPlaying && hints > 0)
              ? () => ref.read(gameProvider.notifier).useHint()
              : null,
          icon: Icon(
            Icons.lightbulb_outline_rounded,
            color: (isPlaying && hints > 0)
                ? c.primary
                : c.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          tooltip: 'Hint ($hints left)',
        ),
        if (hints > 0 && isPlaying)
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
}

class _PauseButton extends ConsumerWidget {
  const _PauseButton();

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
            ? c.primary
            : c.onSurfaceVariant.withValues(alpha: 0.4),
      ),
      tooltip: isPaused ? 'Resume' : 'Pause',
    );
  }
}


class _GameInfoRow extends ConsumerWidget {
  const _GameInfoRow();

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

    final narrow = MediaQuery.sizeOf(context).width < 380;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: narrow ? 10 : 24),
      child: Row(
        children: [
          Expanded(
            child: _InfoTile(
              icon: Icons.timer_outlined,
              value: timeStr,
              label: 'Time',
            ),
          ),
          const _InfoDivider(),
          Expanded(
            child: _InfoTile(
              icon: Icons.close_rounded,
              value: '$mistakes / ${difficulty.maxMistakes}',
              label: 'Mistakes',
              valueColor: mistakes > 0 ? Colors.red.shade600 : null,
            ),
          ),
          const _InfoDivider(),
          Expanded(
            child: _InfoTile(
              icon: Icons.check_circle_outline_rounded,
              value: '${(progress * 100).toInt()}%',
              label: 'Complete',
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
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.value,
    required this.label,
    this.valueColor,
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
              color: valueColor ?? c.onSurface,
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
    final o = context.appColors.outline;
    return Container(
      width: 1,
      height: 38,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            o.withValues(alpha: 0.0),
            o,
            o.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}


class _SudokuGridSection extends ConsumerWidget {
  const _SudokuGridSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(gameStatusProvider);
    final c = context.appColors;

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
    final game = ref.watch(gameProvider);

    if (game.currentBoard.isEmpty) return const SizedBox.shrink();

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
        return _SudokuCell(
          row: row,
          col: col,
          game: game,
          onTap: () => ref.read(gameProvider.notifier).selectCell(row, col),
        );
      },
    );
  }
}


class _SudokuCell extends StatefulWidget {
  final int row;
  final int col;
  final GameState game;
  final VoidCallback onTap;

  const _SudokuCell({
    required this.row,
    required this.col,
    required this.game,
    required this.onTap,
  });

  @override
  State<_SudokuCell> createState() => _SudokuCellState();
}

class _SudokuCellState extends State<_SudokuCell>
    with TickerProviderStateMixin {
  // Flash animation: gold/purple wave when a group completes
  late final AnimationController _flashCtrl;
  Color _flashColor = Colors.transparent;

  // Scale/pop animation: brief scale-up when a correct digit is placed
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  StreamSubscription<_CellFlashEvent>? _flashSub;

  @override
  void initState() {
    super.initState();
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.22), weight: 38),
      TweenSequenceItem(tween: Tween(begin: 1.22, end: 1.0), weight: 62),
    ]).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut));

    _flashSub = _flashBus.stream.listen(_onFlash);
  }

  void _onFlash(_CellFlashEvent e) {
    if (e.row != widget.row || e.col != widget.col) return;
    Future.delayed(Duration(milliseconds: e.delayMs), () {
      if (!mounted) return;
      setState(() => _flashColor = e.color);
      _flashCtrl.forward(from: 0);
    });
  }

  @override
  void didUpdateWidget(_SudokuCell old) {
    super.didUpdateWidget(old);
    if (old.game.currentBoard.isNotEmpty &&
        widget.game.currentBoard.isNotEmpty) {
      final oldVal = old.game.currentBoard[widget.row][widget.col];
      final newVal = widget.game.currentBoard[widget.row][widget.col];
      final isErr =
          widget.game.errorCells.contains('${widget.row},${widget.col}');
      if (oldVal == 0 && newVal != 0 && !isErr) {
        _scaleCtrl.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _flashSub?.cancel();
    _flashCtrl.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  bool get _isSelected =>
      widget.game.selectedRow == widget.row &&
      widget.game.selectedCol == widget.col;

  bool get _isFixed =>
      widget.game.isFixed.isNotEmpty &&
      widget.game.isFixed[widget.row][widget.col];

  bool get _isError =>
      widget.game.errorCells.contains('${widget.row},${widget.col}');

  int get _value => widget.game.currentBoard.isNotEmpty
      ? widget.game.currentBoard[widget.row][widget.col]
      : 0;

  Set<int> get _notes => widget.game.notes.isNotEmpty
      ? widget.game.notes[widget.row][widget.col]
      : const {};

  bool get _hasSelection =>
      widget.game.selectedRow >= 0 && widget.game.selectedCol >= 0;

  bool get _isHighlighted {
    if (!_hasSelection) return false;
    final sr = widget.game.selectedRow;
    final sc = widget.game.selectedCol;
    return widget.row == sr ||
        widget.col == sc ||
        (widget.row ~/ 3 == sr ~/ 3 && widget.col ~/ 3 == sc ~/ 3);
  }

  bool get _isSameNumber {
    if (!_hasSelection || _value == 0 || _isSelected) return false;
    final sr = widget.game.selectedRow;
    final sc = widget.game.selectedCol;
    if (sr < 0 || sc < 0) return false;
    final selVal = widget.game.currentBoard[sr][sc];
    return selVal != 0 && selVal == _value;
  }

  Color _baseBg(BuildContext context) {
    final c = context.appColors;
    if (_isError) return const Color(0xFFFF5252);
    if (_isSelected) return c.cellSelected;
    if (_isSameNumber) return c.cellSameNumber;
    if (_isHighlighted) return c.cellHouseHighlight;
    return c.pureWhite;
  }

  Color get _textColor {
    if (_isError) return Colors.white;
    if (_isFixed) return const Color(0xFF1A1A1A);
    return const Color(0xFF2D2D2D);
  }

  FontWeight get _fontWeight =>
      _isFixed ? FontWeight.w800 : FontWeight.w600;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: _value != 0
          ? Text(
              '$_value',
              style: TextStyle(
                color: _textColor,
                fontWeight: _fontWeight,
                fontSize: 20,
                height: 1,
              ),
            )
          : _notes.isNotEmpty
              ? _NoteGrid(notes: _notes)
              : null,
    );

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flashCtrl, _scaleCtrl]),
        builder: (ctx, child) {
          // Compute flash overlay alpha (rise 0→0.35, fall 0.35→1.0)
          final fv = _flashCtrl.value;
          final fa =
              fv < 0.35 ? fv / 0.35 : 1.0 - (fv - 0.35) / 0.65;
          final flashOverlay =
              _flashColor.withValues(alpha: fa * 0.62);
          final bg =
              Color.alphaBlend(flashOverlay, _baseBg(ctx));

          return Transform.scale(
            scale: _scaleAnim.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 75),
              color: bg,
              child: child,
            ),
          );
        },
        child: content,
      ),
    );
  }
}


class _NoteGrid extends StatelessWidget {
  final Set<int> notes;

  const _NoteGrid({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: Column(
        children: List.generate(
          3,
          (rowIdx) => Expanded(
            child: Row(
              children: List.generate(3, (colIdx) {
                final num = rowIdx * 3 + colIdx + 1;
                return Expanded(
                  child: Center(
                    child: notes.contains(num)
                        ? Text(
                            '$num',
                            style: TextStyle(
                              fontSize: 7,
                              color: context.appColors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              height: 1,
                            ),
                          )
                        : null,
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}


class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay();

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
        color: c.surface.withValues(alpha: 0.93),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: c.container,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: c.primary.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.pause_rounded,
                  size: 38,
                  color: c.primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Paused',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: c.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap ▶ in the app bar to resume',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
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
        color: c.surface.withValues(alpha: 0.9),
        child: Center(
          child: CircularProgressIndicator(
            color: c.primary,
            strokeWidth: 3,
          ),
        ),
      );
  }
}


class _GridLinePainter extends CustomPainter {
  const _GridLinePainter({
    required this.outline,
    required this.primary,
  });

  final Color outline;
  final Color primary;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 9;

    final thin = Paint()
      ..color = outline.withValues(alpha: 0.7)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    final thick = Paint()
      ..color = primary.withValues(alpha: 0.40)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final outer = Paint()
      ..color = primary.withValues(alpha: 0.60)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    for (var i = 1; i < 9; i++) {
      final p = i % 3 == 0 ? thick : thin;
      final x = i * cell;
      final y = i * cell;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(4),
      ),
      outer,
    );
  }

  @override
  bool shouldRepaint(covariant _GridLinePainter old) =>
      old.outline != outline || old.primary != primary;
}


class _NumPad extends ConsumerWidget {
  const _NumPad();

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
                label: 'Notes',
                isActive: noteMode,
                isEnabled: isPlaying,
                onTap: isPlaying
                    ? () => ref.read(gameProvider.notifier).toggleNoteMode()
                    : null,
              ),
              const SizedBox(width: 40),
              _ActionIconButton(
                icon: Icons.backspace_outlined,
                label: 'Erase',
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

/// Remaining count for each digit (9 − on board), above the numpad.
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


class _NumButton extends StatelessWidget {
  final int number;
  final bool isComplete;
  final bool isEnabled;
  final bool isNoteMode;
  final VoidCallback? onTap;

  const _NumButton({
    required this.number,
    required this.isComplete,
    required this.isEnabled,
    required this.isNoteMode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final textColor = isComplete
        ? c.outline
        : isEnabled
            ? (isNoteMode ? c.dark : c.primary)
            : c.onSurfaceVariant.withValues(alpha: 0.35);

    return Padding(
      padding: const EdgeInsets.all(2.5),
      child: Material(
        color: isComplete
            ? c.softWhite
            : isNoteMode
                ? c.notePadBackground
                : c.pureWhite,
        borderRadius: BorderRadius.circular(14),
        elevation: isEnabled ? 1.5 : 0,
        shadowColor: c.shadow,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          splashColor: c.primary.withValues(alpha: 0.16),
          highlightColor: c.container.withValues(alpha: 0.55),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isEnabled
                    ? (isNoteMode
                        ? c.primary.withValues(alpha: 0.45)
                        : c.outline)
                    : c.outline.withValues(alpha: 0.35),
              ),
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  fontSize: isNoteMode ? 18 : 22,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  height: 1,
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
    final Color bgColor;
    final Color iconColor;
    final Color labelColor;

    if (!isEnabled) {
      bgColor = c.softWhite;
      iconColor = c.outline;
      labelColor = c.outline;
    } else if (isActive) {
      bgColor = c.primary;
      iconColor = Colors.white;
      labelColor = c.primary;
    } else {
      bgColor = c.container;
      iconColor = c.dark;
      labelColor = c.onSurfaceVariant;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          elevation: isEnabled ? 1.5 : 0,
          shadowColor: c.shadow,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            splashColor: c.primary.withValues(alpha: 0.2),
            highlightColor: c.container.withValues(alpha: 0.4),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
              child: Icon(icon, color: iconColor, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: labelColor,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}


class _DuelCountdownOverlay extends StatefulWidget {
  final int value;
  const _DuelCountdownOverlay({required this.value});

  @override
  State<_DuelCountdownOverlay> createState() => _DuelCountdownOverlayState();
}

class _DuelCountdownOverlayState extends State<_DuelCountdownOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void didUpdateWidget(_DuelCountdownOverlay old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _scaleCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGo = widget.value <= 0;
    final label = isGo ? 'GO!' : '${widget.value}';

    return AbsorbPointer(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: ScaleTransition(
            scale: Tween<double>(begin: 1.6, end: 1.0).animate(
              CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut),
            ),
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: isGo ? 80 : 100,
                fontWeight: FontWeight.w900,
                color: isGo ? const Color(0xFF66BB6A) : Colors.white,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _ConfettiCannon extends StatelessWidget {
  final ConfettiController controller;
  final AlignmentGeometry alignment;
  final double blastDirection;

  const _ConfettiCannon({
    required this.controller,
    required this.alignment,
    required this.blastDirection,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors.confettiColors();
    return Align(
      alignment: alignment,
      child: ConfettiWidget(
        confettiController: controller,
        blastDirectionality: BlastDirectionality.directional,
        blastDirection: blastDirection,
        particleDrag: 0.04,
        emissionFrequency: 0.07,
        numberOfParticles: 18,
        gravity: 0.32,
        shouldLoop: false,
        colors: colors,
        maximumSize: const Size(16, 8),
        minimumSize: const Size(7, 4),
      ),
    );
  }
}


class _CelebrationOverlay extends ConsumerWidget {
  const _CelebrationOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final size = MediaQuery.of(context).size;
    final c = context.appColors;

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
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                _SparkleRow(),

                const SizedBox(height: 28),

                _TrophyBadge(),

                const SizedBox(height: 32),

                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: c.titleShaderColors,
                  ).createShader(bounds),
                  child: Text(
                    'Amazing!',
                    style: GoogleFonts.dancingScript(
                      fontSize: 72,
                      fontWeight: FontWeight.w700,
                      color: Colors.white, // ShaderMask bunu boyar
                      height: 1,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'You completed the Sudoku perfectly ✨',
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
                        ref
                            .read(gameProvider.notifier)
                            .startGame(game.difficulty);
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      label: Text(
                        'New Game',
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
                    'Main Menu',
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


class _SparkleRow extends StatefulWidget {
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
      ),
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
    final hintCap =
        game.isDuel ? 0 : game.difficulty.soloHintsAllowed;
    final hintsUsed = hintCap - game.hintsRemaining;
    final perfectScore = game.mistakeCount == 0 && hintsUsed == 0;
    final c = context.appColors;

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
      ),
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
                      'Perfect score!',
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
                  label: 'Time',
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
                  label: 'Mistakes',
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
                  label: 'Hints',
                  value: game.isDuel ? 'Off' : '$hintsUsed used',
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


class _LostDialog extends ConsumerWidget {
  const _LostDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final theme = Theme.of(context);
    final c = context.appColors;

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
              'Game Over',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.red.shade500,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'You ran out of mistakes.\nTry again and take your time!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: c.onSurfaceVariant,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            _StatRowSimple(
              icon: Icons.close_rounded,
              label: 'Mistakes',
              value: '${game.mistakeCount} / ${game.difficulty.maxMistakes}',
              valueColor: Colors.red.shade600,
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref
                      .read(gameProvider.notifier)
                      .startGame(game.difficulty);
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
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
                child: const Text('Main Menu'),
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
      ),
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
