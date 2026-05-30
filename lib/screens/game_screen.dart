import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/game_state.dart';
import '../providers/daily_challenge_provider.dart';
import '../providers/duel_provider.dart';
import '../providers/game_provider.dart';
import '../providers/theme_provider.dart';
import '../services/sound_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_presets.dart';
import '../widgets/effects/ambient_background.dart';
import '../widgets/game/game_info.dart';
import '../widgets/game/game_overlays.dart';
import '../widgets/game/numpad.dart';
import '../widgets/game/sudoku_cell.dart';
import '../widgets/game/sudoku_grid.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const GameScreen());

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final ConfettiController _confettiLeft;
  late final ConfettiController _confettiRight;
  final _flashBus = StreamController<CellFlashEvent>.broadcast();

  bool _countdownActive = false;
  int _countdownValue = 3;
  Timer? _countdownTimer;
  Timer? _duelOpponentTimeout;
  bool _opponentForfeitShown = false;

  @override
  void initState() {
    super.initState();
    _confettiLeft =
        ConfettiController(duration: const Duration(milliseconds: 1500));
    _confettiRight =
        ConfettiController(duration: const Duration(milliseconds: 1500));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final game = ref.read(gameProvider);
      // Fresh duel: timer not started until countdown ends ([GameNotifier.startDuelTimer]).
      if (game.isDuel &&
          game.status == GameStatus.playing &&
          game.elapsedSeconds == 0) {
        _startCountdown();
      }
    });
  }

  @override
  void dispose() {
    _confettiLeft.dispose();
    _confettiRight.dispose();
    _flashBus.close();
    _countdownTimer?.cancel();
    _duelOpponentTimeout?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _countdownActive = true;
      _countdownValue = 3;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdownValue > 0) {
          _countdownValue--;
        } else {
          _countdownActive = false;
          _countdownTimer?.cancel();
          ref.read(gameProvider.notifier).startDuelTimer();
        }
      });
    });
  }

  void _celebrate() {
    _confettiLeft.play();
    _confettiRight.play();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CelebrationOverlay(),
    );
  }

  /// Fires staggered flash events to every cell in a group, creating a sweep.
  /// Row → left to right | Column → top to bottom | Box → top-left to bottom-right.
  void _fireSweepFlash(String groupKey, Color color, {required int baseDelayMs}) {
    final cells = _cellsForGroup(groupKey);
    const perCellMs = 42; // stagger between consecutive cells
    for (int i = 0; i < cells.length; i++) {
      final (row, col) = cells[i];
      _flashBus.add(CellFlashEvent(
        row: row,
        col: col,
        delayMs: baseDelayMs + i * perCellMs,
        color: color,
      ));
    }
  }

  List<(int, int)> _cellsForGroup(String key) {
    if (key.startsWith('r')) {
      final r = int.parse(key.substring(1));
      return [for (int c = 0; c < 9; c++) (r, c)];
    } else if (key.startsWith('c')) {
      final col = int.parse(key.substring(1));
      return [for (int r = 0; r < 9; r++) (r, col)];
    } else {
      // box key format: 'b{boxRow}{boxCol}'
      final br = int.parse(key[1]) * 3;
      final bc = int.parse(key[2]) * 3;
      return [
        for (int r = br; r < br + 3; r++)
          for (int c = bc; c < bc + 3; c++) (r, c),
      ];
    }
  }

  void _showLostDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LostDialog(),
    );
  }

  void _startDuelOpponentTimeout() {
    _duelOpponentTimeout?.cancel();
    _duelOpponentTimeout = Timer(const Duration(minutes: 3), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final dark = ref.watch(brightnessProvider) == AppBrightness.dark;

    // ── Group completion: sweep flash + sound + haptic ──────────────────────
    ref.listen<Set<String>>(completedGroupsProvider, (prev, next) {
      // prev is null only on first emission — treat as empty (no new completions)
      final newGroups = next.difference(prev ?? const {});
      if (newGroups.isEmpty) return;

      final newLines =
          newGroups.where((k) => k.startsWith('r') || k.startsWith('c')).toList();
      final newBoxes =
          newGroups.where((k) => k.startsWith('b')).toList();

      // Lines: immediate sweep + sound
      if (newLines.isNotEmpty) {
        SoundService.playLine();
        HapticFeedback.mediumImpact();
        for (final key in newLines) {
          _fireSweepFlash(key, c.primary, baseDelayMs: 0);
        }
      }

      // Boxes: staggered after lines (or immediate if no lines)
      final boxBase = newLines.isNotEmpty ? 160 : 0;
      if (newBoxes.isNotEmpty) {
        Future.delayed(Duration(milliseconds: boxBase), () {
          if (!mounted) return;
          SoundService.playBox();
          HapticFeedback.lightImpact();
        });
        for (final key in newBoxes) {
          _fireSweepFlash(key, const Color(0xFFFFD54F), baseDelayMs: boxBase);
        }
      }
    });

    ref.listen<GameStatus>(gameStatusProvider, (prev, next) {
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
            _startDuelOpponentTimeout();
          }
        }
        unawaited(
          ref.read(scoreProvider.notifier).recordWin(
                game.difficulty,
                game.elapsedSeconds,
                game.mistakeCount,
              ),
        );
        if (game.isDailyChallenge) {
          unawaited(
            ref.read(dailyChallengeProvider.notifier).recordCompletion(
                  game.elapsedSeconds,
                  game.mistakeCount,
                ),
          );
        }
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

    // ── Duel: detect opponent forfeit and show snackbar ─────────────────────
    final duelCode = ref.watch(
      gameProvider.select((g) => g.isDuel ? (g.duelRoomCode ?? '') : ''),
    );
    ref.listen(duelRoomDocStreamProvider(duelCode), (_, next) {
      if (_opponentForfeitShown) return;
      final data = next.valueOrNull?.data();
      if (data == null) return;
      final isHost = ref.read(gameProvider).duelIsHost;
      final opponentKey = isHost ? 'guestForfeit' : 'hostForfeit';
      if (data[opponentKey] == true) {
        _opponentForfeitShown = true;
        _duelOpponentTimeout?.cancel();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).opponentLeftYouWin),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    return FlashBusScope(
      stream: _flashBus.stream,
      child: Stack(
        children: [
          Positioned.fill(
            child: AmbientBackground(colors: c, dark: dark, intensity: 0.5),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
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
              title: const AppBarTitle(),
              actions: const [
                SoundToggleButton(),
                SizedBox(width: 2),
                HintButton(),
                SizedBox(width: 2),
                PauseButton(),
                SizedBox(width: 4),
              ],
            ),
            body: const SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 10),
                  GameInfoRow(),
                  SizedBox(height: 10),
                  Expanded(
                    child: Center(child: SudokuGridSection()),
                  ),
                  SizedBox(height: 10),
                  NumPad(),
                  SizedBox(height: 14),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.topLeft,
              child: ConfettiWidget(
                confettiController: _confettiLeft,
                blastDirection: pi / 2.6,
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.topRight,
              child: ConfettiWidget(
                confettiController: _confettiRight,
                blastDirection: pi - pi / 2.6,
              ),
            ),
          ),
          if (_countdownActive)
            DuelCountdownOverlay(value: _countdownValue),
        ],
      ),
    );
  }
}
