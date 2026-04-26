import '../game_logic/sudoku_engine.dart';

enum GameStatus {
  idle,
  generating,
  playing,
  paused,
  won,
  lost,
}

/// Immutable game snapshot; updates replace the whole object.
class GameState {
  const GameState({
    required this.difficulty,
    required this.solution,
    required this.initialPuzzle,
    required this.currentBoard,
    required this.isFixed,
    required this.errorCells,
    required this.mistakeCount,
    required this.hintsRemaining,
    required this.status,
    required this.selectedRow,
    required this.selectedCol,
    required this.elapsedSeconds,
    required this.notes,
    required this.noteMode,
    this.isDuel = false,
    this.duelRoomCode,
    this.duelIsHost = false,
  });

  final Difficulty difficulty;
  final List<List<int>> solution;
  final List<List<int>> initialPuzzle;
  final List<List<int>> currentBoard;
  final List<List<bool>> isFixed;
  final Set<String> errorCells;
  final int mistakeCount;
  final int hintsRemaining;
  final GameStatus status;
  final int selectedRow;
  final int selectedCol;
  final int elapsedSeconds;
  final List<List<Set<int>>> notes;
  final bool noteMode;

  /// Head-to-head race: same puzzle as opponent; hints disabled.
  final bool isDuel;
  final String? duelRoomCode;
  final bool duelIsHost;

  factory GameState.initial() => GameState(
        difficulty: Difficulty.easy,
        solution: const [],
        initialPuzzle: const [],
        currentBoard: const [],
        isFixed: const [],
        errorCells: const {},
        mistakeCount: 0,
        hintsRemaining: 3,
        status: GameStatus.idle,
        selectedRow: -1,
        selectedCol: -1,
        elapsedSeconds: 0,
        notes: const [],
        noteMode: false,
        isDuel: false,
        duelRoomCode: null,
        duelIsHost: false,
      );

  bool get hasSelection => selectedRow >= 0 && selectedCol >= 0;

  bool get isSelectionFixed =>
      hasSelection &&
      isFixed.isNotEmpty &&
      isFixed[selectedRow][selectedCol];

  int get filledCells {
    if (currentBoard.isEmpty) return 0;
    return currentBoard.expand((r) => r).where((v) => v != 0).length;
  }

  double get progress =>
      currentBoard.isEmpty ? 0.0 : filledCells / 81.0;

  String get formattedTime {
    final m = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  GameState copyWith({
    Difficulty? difficulty,
    List<List<int>>? solution,
    List<List<int>>? initialPuzzle,
    List<List<int>>? currentBoard,
    List<List<bool>>? isFixed,
    Set<String>? errorCells,
    int? mistakeCount,
    int? hintsRemaining,
    GameStatus? status,
    int? selectedRow,
    int? selectedCol,
    int? elapsedSeconds,
    List<List<Set<int>>>? notes,
    bool? noteMode,
    bool? isDuel,
    String? duelRoomCode,
    bool? duelIsHost,
  }) =>
      GameState(
        difficulty: difficulty ?? this.difficulty,
        solution: solution ?? this.solution,
        initialPuzzle: initialPuzzle ?? this.initialPuzzle,
        currentBoard: currentBoard ?? this.currentBoard,
        isFixed: isFixed ?? this.isFixed,
        errorCells: errorCells ?? this.errorCells,
        mistakeCount: mistakeCount ?? this.mistakeCount,
        hintsRemaining: hintsRemaining ?? this.hintsRemaining,
        status: status ?? this.status,
        selectedRow: selectedRow ?? this.selectedRow,
        selectedCol: selectedCol ?? this.selectedCol,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        notes: notes ?? this.notes,
        noteMode: noteMode ?? this.noteMode,
        isDuel: isDuel ?? this.isDuel,
        duelRoomCode: duelRoomCode ?? this.duelRoomCode,
        duelIsHost: duelIsHost ?? this.duelIsHost,
      );
}
