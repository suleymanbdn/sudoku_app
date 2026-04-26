import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game_logic/sudoku_engine.dart';
import '../models/game_state.dart';
import '../persistence/game_save_storage.dart';
import '../services/sound_service.dart';
import 'theme_provider.dart';


/// Game rules, timer, and board updates. Puzzle generation runs in [compute].
class GameNotifier extends StateNotifier<GameState> {
  GameNotifier(this._prefs)
      : super(tryLoadActiveGame(_prefs) ?? GameState.initial()) {
    if (state.status == GameStatus.playing) {
      _startTimer();
    }
  }

  final SharedPreferences _prefs;
  Timer? _timer;
  Timer? _saveDebounce;

  @override
  set state(GameState value) {
    super.state = value;
    _onStateCommitted(value);
  }

  void _onStateCommitted(GameState value) {
    if (value.status == GameStatus.won || value.status == GameStatus.lost) {
      _saveDebounce?.cancel();
      unawaited(clearActiveGameSave(_prefs));
      return;
    }
    if (value.status != GameStatus.playing &&
        value.status != GameStatus.paused) {
      return;
    }
    if (value.solution.isEmpty) return;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 600), () {
      unawaited(saveActiveGame(_prefs, state));
    });
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    if (state.status == GameStatus.playing ||
        state.status == GameStatus.paused) {
      unawaited(saveActiveGame(_prefs, state));
    }
    _timer?.cancel();
    super.dispose();
  }

  Future<void> startGame(Difficulty difficulty) => _beginNewRound(
        difficulty: difficulty,
        computeArg: difficulty.index,
        isDuel: false,
        duelRoomCode: null,
        duelIsHost: false,
        hintsRemaining: difficulty.soloHintsAllowed,
      );

  /// Same puzzle as [roomCode] (see [DuelRoomCode]); hints off for fairness.
  Future<void> startDuelGame({
    required Difficulty difficulty,
    required int seed,
    required String roomCode,
    required bool duelIsHost,
  }) =>
      _beginNewRound(
        difficulty: difficulty,
        computeArg: <String, dynamic>{'d': difficulty.index, 'seed': seed},
        isDuel: true,
        duelRoomCode: roomCode,
        duelIsHost: duelIsHost,
        hintsRemaining: 0,
      );

  Future<void> _beginNewRound({
    required Difficulty difficulty,
    required Object computeArg,
    required bool isDuel,
    required String? duelRoomCode,
    required bool duelIsHost,
    required int hintsRemaining,
  }) async {
    _stopTimer();
    await clearActiveGameSave(_prefs);
    state = state.copyWith(status: GameStatus.generating);

    final raw = await compute(generatePuzzleInIsolate, computeArg);
    final solution = raw[0];
    final puzzle = raw[1];

    final isFixed = List.generate(
      9,
      (r) => List.generate(9, (c) => puzzle[r][c] != 0),
    );

    final emptyNotes = List.generate(
      9,
      (_) => List.generate(9, (_) => <int>{}),
    );

    state = GameState(
      difficulty: difficulty,
      solution: solution,
      initialPuzzle: puzzle,
      currentBoard: puzzle.map((r) => List<int>.from(r)).toList(),
      isFixed: isFixed,
      errorCells: const {},
      mistakeCount: 0,
      hintsRemaining: hintsRemaining,
      status: GameStatus.playing,
      selectedRow: -1,
      selectedCol: -1,
      elapsedSeconds: 0,
      notes: emptyNotes,
      noteMode: false,
      isDuel: isDuel,
      duelRoomCode: duelRoomCode,
      duelIsHost: duelIsHost,
    );

    _startTimer();
  }

  Future<void> resetGame() => startGame(state.difficulty);

  void pauseGame() {
    if (state.status != GameStatus.playing) return;
    _stopTimer();
    _saveDebounce?.cancel();
    state = state.copyWith(status: GameStatus.paused);
    unawaited(saveActiveGame(_prefs, state));
  }

  void resumeGame() {
    if (state.status != GameStatus.paused) return;
    state = state.copyWith(status: GameStatus.playing);
    _startTimer();
  }

  void selectCell(int row, int col) {
    if (state.status != GameStatus.playing) return;
    if (state.selectedRow == row && state.selectedCol == col) {
      state = state.copyWith(selectedRow: -1, selectedCol: -1);
    } else {
      state = state.copyWith(selectedRow: row, selectedCol: col);
    }
  }

  void clearSelection() {
    state = state.copyWith(selectedRow: -1, selectedCol: -1);
  }

  void enterNumber(int number) {
    if (!state.hasSelection) return;
    if (state.isSelectionFixed) return;
    if (state.status != GameStatus.playing) return;

    if (state.noteMode && number != 0) {
      toggleNote(number);
      return;
    }

    final row = state.selectedRow;
    final col = state.selectedCol;

    if (state.currentBoard[row][col] == number) return;

    final board = state.currentBoard.map((r) => List<int>.from(r)).toList();
    board[row][col] = number;

    final notes = _cloneNotesDeep(state.notes);
    _applyPlacedDigitToNotes(notes, row, col, number);

    final errors = _errorKeysForBoard(board);

    var mistakes = state.mistakeCount;
    final cellKey = '$row,$col';
    final wasAlreadyError = state.errorCells.contains(cellKey);
    final isNowError = errors.contains(cellKey);
    final isNewError = number != 0 && isNowError && !wasAlreadyError;

    if (isNewError) {
      mistakes++;
      HapticFeedback.heavyImpact();
    } else if (number != 0 && !isNowError) {
      HapticFeedback.lightImpact();
    }

    GameStatus newStatus = state.status;

    if (mistakes >= state.difficulty.maxMistakes) {
      newStatus = GameStatus.lost;
      _stopTimer();
    } else if (errors.isEmpty && SudokuEngine.isSolved(board)) {
      newStatus = GameStatus.won;
      _stopTimer();
    }

    state = state.copyWith(
      currentBoard: board,
      notes: notes,
      errorCells: errors,
      mistakeCount: mistakes,
      status: newStatus,
    );

    if (isNewError && newStatus == GameStatus.playing) {
      Future.delayed(const Duration(milliseconds: 650), () {
        _clearErrorCell(row, col);
      });
    }
  }

  void _clearErrorCell(int row, int col) {
    if (state.status != GameStatus.playing) return;
    if (!state.errorCells.contains('$row,$col')) return;

    final board = state.currentBoard.map((r) => List<int>.from(r)).toList();
    board[row][col] = 0;

    final errors = Set<String>.from(state.errorCells)..remove('$row,$col');

    state = state.copyWith(
      currentBoard: board,
      errorCells: errors,
    );
  }

  void clearSelectedCell() {
    if (!state.hasSelection) return;
    if (state.isSelectionFixed) return;
    if (state.status != GameStatus.playing) return;

    final row = state.selectedRow;
    final col = state.selectedCol;

    final hasNotes =
        state.notes.isNotEmpty && state.notes[row][col].isNotEmpty;

    if (state.noteMode && hasNotes) {
      final newNotes = _cloneNotesDeep(state.notes);
      newNotes[row][col] = {};
      state = state.copyWith(notes: newNotes);
      return;
    }

    enterNumber(0);
  }

  void toggleNoteMode() {
    state = state.copyWith(noteMode: !state.noteMode);
  }

  void toggleNote(int number) {
    if (!state.hasSelection) return;
    if (state.isSelectionFixed) return;
    if (state.status != GameStatus.playing) return;

    final row = state.selectedRow;
    final col = state.selectedCol;

    if (state.currentBoard[row][col] != 0) return;

    final notes = _cloneNotesDeep(state.notes);

    if (notes[row][col].contains(number)) {
      notes[row][col].remove(number);
    } else {
      notes[row][col].add(number);
    }

    state = state.copyWith(notes: notes);
  }

  void useHint() {
    if (state.hintsRemaining <= 0) return;
    if (state.status != GameStatus.playing) return;

    final board = state.currentBoard.map((r) => List<int>.from(r)).toList();
    int row;
    int col;
    int correct;

    final useSelected = state.hasSelection &&
        !state.isSelectionFixed &&
        (board[state.selectedRow][state.selectedCol] == 0 ||
            board[state.selectedRow][state.selectedCol] !=
                state.solution[state.selectedRow][state.selectedCol]);

    if (useSelected) {
      row = state.selectedRow;
      col = state.selectedCol;
      correct = state.solution[row][col];
    } else {
      final auto = SudokuEngine.findAutoHintPlacement(
        board,
        state.isFixed,
        state.solution,
      );
      if (auto == null) return;
      row = auto.row;
      col = auto.col;
      correct = auto.digit;
    }

    if (board[row][col] == correct) return;

    board[row][col] = correct;

    final errors = _errorKeysForBoard(board);

    final notes = _cloneNotesDeep(state.notes);
    _applyPlacedDigitToNotes(notes, row, col, correct);

    final won = errors.isEmpty && SudokuEngine.isSolved(board);
    if (won) _stopTimer();

    HapticFeedback.lightImpact();

    state = state.copyWith(
      currentBoard: board,
      notes: notes,
      errorCells: errors,
      hintsRemaining: state.hintsRemaining - 1,
      status: won ? GameStatus.won : state.status,
      selectedRow: row,
      selectedCol: col,
    );
  }

  List<List<Set<int>>> _cloneNotesDeep(List<List<Set<int>>> source) =>
      source.map((r) => r.map(Set<int>.from).toList()).toList();

  Set<String> _errorKeysForBoard(List<List<int>> board) {
    final sol = state.solution;
    final errors = <String>{};
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board[r][c] != 0 && board[r][c] != sol[r][c]) {
          errors.add('$r,$c');
        }
      }
    }
    return errors;
  }

  static void _applyPlacedDigitToNotes(
    List<List<Set<int>>> notes,
    int row,
    int col,
    int digit,
  ) {
    notes[row][col] = {};
    if (digit == 0) return;
    for (var i = 0; i < 9; i++) {
      notes[row][i].remove(digit);
      notes[i][col].remove(digit);
    }
    final br = (row ~/ 3) * 3;
    final bc = (col ~/ 3) * 3;
    for (var r = br; r < br + 3; r++) {
      for (var c = bc; c < bc + 3; c++) {
        notes[r][c].remove(digit);
      }
    }
  }

  void _tick() {
    if (state.status == GameStatus.playing) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }
}


final gameProvider =
    StateNotifierProvider<GameNotifier, GameState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return GameNotifier(prefs);
});

final difficultyProvider = Provider<Difficulty>(
  (ref) => ref.watch(gameProvider).difficulty,
);

final gameStatusProvider = Provider<GameStatus>(
  (ref) => ref.watch(gameProvider).status,
);

final mistakeCountProvider = Provider<int>(
  (ref) => ref.watch(gameProvider).mistakeCount,
);

final hintsRemainingProvider = Provider<int>(
  (ref) => ref.watch(gameProvider).hintsRemaining,
);

final elapsedSecondsProvider = Provider<int>(
  (ref) => ref.watch(gameProvider).elapsedSeconds,
);

final progressProvider = Provider<double>(
  (ref) => ref.watch(gameProvider).progress,
);

final noteModeProvider = Provider<bool>(
  (ref) => ref.watch(gameProvider).noteMode,
);

/// Board fields only (no timer) so the grid does not rebuild every second.
class BoardSnapshot {
  final List<List<int>> currentBoard;
  final List<List<bool>> isFixed;
  final Set<String> errorCells;
  final int selectedRow;
  final int selectedCol;
  final List<List<Set<int>>> notes;
  final GameStatus status;

  const BoardSnapshot({
    required this.currentBoard,
    required this.isFixed,
    required this.errorCells,
    required this.selectedRow,
    required this.selectedCol,
    required this.notes,
    required this.status,
  });

  factory BoardSnapshot.from(GameState s) => BoardSnapshot(
        currentBoard: s.currentBoard,
        isFixed: s.isFixed,
        errorCells: s.errorCells,
        selectedRow: s.selectedRow,
        selectedCol: s.selectedCol,
        notes: s.notes,
        status: s.status,
      );

  int countOnBoard(int num) {
    if (currentBoard.length != 9) return 0;
    var n = 0;
    for (final row in currentBoard) {
      for (final v in row) {
        if (v == num) n++;
      }
    }
    return n;
  }

  int remainingForDigit(int num) {
    final r = 9 - countOnBoard(num);
    return r < 0 ? 0 : r;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BoardSnapshot) return false;
    return identical(currentBoard, other.currentBoard) &&
        identical(isFixed, other.isFixed) &&
        errorCells == other.errorCells &&
        selectedRow == other.selectedRow &&
        selectedCol == other.selectedCol &&
        identical(notes, other.notes) &&
        status == other.status;
  }

  @override
  int get hashCode => Object.hash(
        identityHashCode(currentBoard),
        identityHashCode(isFixed),
        errorCells,
        selectedRow,
        selectedCol,
        identityHashCode(notes),
        status,
      );
}

final boardSnapshotProvider = Provider<BoardSnapshot>(
  (ref) => BoardSnapshot.from(ref.watch(gameProvider)),
);


class GameScore {
  final Difficulty difficulty;
  final int timeSeconds;
  final int mistakeCount;

  const GameScore({
    required this.difficulty,
    required this.timeSeconds,
    required this.mistakeCount,
  });

  Map<String, dynamic> toJson() => {
        'd': difficulty.index,
        't': timeSeconds,
        'm': mistakeCount,
      };

  static GameScore? fromJson(Map<String, dynamic> json) {
    final d = json['d'];
    final t = json['t'];
    final m = json['m'];
    if (d is! int || t is! int || m is! int) return null;
    if (d < 0 || d >= Difficulty.values.length) return null;
    return GameScore(
      difficulty: Difficulty.values[d],
      timeSeconds: t,
      mistakeCount: m,
    );
  }
}

class ScoreNotifier extends StateNotifier<List<GameScore>> {
  ScoreNotifier(this._prefs) : super(_loadScores(_prefs));

  final SharedPreferences _prefs;

  static const _prefsKey = 'game_scores_v1';

  static List<GameScore> _loadScores(SharedPreferences prefs) {
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return [];
      final out = <GameScore>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final s = GameScore.fromJson(Map<String, dynamic>.from(item));
        if (s != null) out.add(s);
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  Future<void> _persist() async {
    final raw = jsonEncode(state.map((s) => s.toJson()).toList());
    await _prefs.setString(_prefsKey, raw);
  }

  Future<void> recordWin(
    Difficulty difficulty,
    int timeSeconds,
    int mistakeCount,
  ) async {
    state = [
      ...state,
      GameScore(
        difficulty: difficulty,
        timeSeconds: timeSeconds,
        mistakeCount: mistakeCount,
      ),
    ];
    await _persist();
  }

  int? bestTime(Difficulty difficulty) {
    final wins =
        state.where((s) => s.difficulty == difficulty).map((s) => s.timeSeconds);
    if (wins.isEmpty) return null;
    return wins.reduce((a, b) => a < b ? a : b);
  }

  int totalWins(Difficulty difficulty) =>
      state.where((s) => s.difficulty == difficulty).length;
}

final scoreProvider =
    StateNotifierProvider<ScoreNotifier, List<GameScore>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ScoreNotifier(prefs);
});

// ---------------------------------------------------------------------------
// Completion detection
// ---------------------------------------------------------------------------

/// Returns the set of group keys that are currently fully and correctly filled.
/// Row keys: 'r0'–'r8' | Column keys: 'c0'–'c8' | Box keys: 'b00'–'b22'.
final completedGroupsProvider = Provider<Set<String>>((ref) {
  final board = ref.watch(gameProvider.select((g) => g.currentBoard));
  if (board.isEmpty) return const {};
  final groups = <String>{};
  for (int i = 0; i < 9; i++) {
    final row = [for (int c = 0; c < 9; c++) board[i][c]];
    if (!row.contains(0) && {...row}.length == 9) groups.add('r$i');

    final col = [for (int r = 0; r < 9; r++) board[r][i]];
    if (!col.contains(0) && {...col}.length == 9) groups.add('c$i');

    final br = (i ~/ 3) * 3;
    final bc = (i % 3) * 3;
    final box = [
      for (int r = br; r < br + 3; r++)
        for (int c = bc; c < bc + 3; c++) board[r][c],
    ];
    if (!box.contains(0) && {...box}.length == 9) {
      groups.add('b${i ~/ 3}${i % 3}');
    }
  }
  return groups;
});

// ---------------------------------------------------------------------------
// Sound toggle
// ---------------------------------------------------------------------------

class SoundEnabledNotifier extends StateNotifier<bool> {
  SoundEnabledNotifier(this._prefs) : super(_prefs.getBool(_key) ?? true) {
    SoundService.enabled = state;
  }

  static const _key = 'sound_enabled';
  final SharedPreferences _prefs;

  Future<void> toggle() async {
    final next = !state;
    state = next;
    SoundService.enabled = next;
    await _prefs.setBool(_key, next);
  }
}

final soundEnabledProvider =
    StateNotifierProvider<SoundEnabledNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SoundEnabledNotifier(prefs);
});
