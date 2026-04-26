import 'dart:math';

enum Difficulty {
  easy,
  medium,
  hard,
  expert;

  String get label => switch (this) {
        Difficulty.easy => 'Easy',
        Difficulty.medium => 'Medium',
        Difficulty.hard => 'Hard',
        Difficulty.expert => 'Expert',
      };

  int get cellsToRemove => switch (this) {
        Difficulty.easy => 36,
        Difficulty.medium => 46,
        Difficulty.hard => 52,
        Difficulty.expert => 58,
      };

  int get maxMistakes => switch (this) {
        Difficulty.easy => 5,
        Difficulty.medium => 3,
        Difficulty.hard => 3,
        Difficulty.expert => 2,
      };

  /// Hints in solo play (duel always uses 0).
  int get soloHintsAllowed => switch (this) {
        Difficulty.expert => 1,
        _ => 3,
      };
}

/// Pure Dart: generation, validation, solving (no Flutter).
class SudokuEngine {
  SudokuEngine._();

  static List<List<int>> generateSolution([Random? rng]) {
    final r = rng ?? Random();
    final board = List.generate(9, (_) => List.filled(9, 0));
    _fillBoard(board, r);
    return board;
  }

  static List<List<int>> createPuzzle(
    List<List<int>> solution,
    Difficulty difficulty, [
    Random? rng,
  ]) {
    final r = rng ?? Random();
    final puzzle = solution.map((row) => List<int>.from(row)).toList();
    final target = difficulty.cellsToRemove;

    final positions = List.generate(81, (i) => i)..shuffle(r);
    var removed = 0;

    for (final idx in positions) {
      if (removed >= target) break;

      final row = idx ~/ 9;
      final col = idx % 9;
      final backup = puzzle[row][col];

      puzzle[row][col] = 0;

      if (_hasUniqueSolution(puzzle)) {
        removed++;
      } else {
        puzzle[row][col] = backup;
      }
    }

    return puzzle;
  }

  static bool isSolved(List<List<int>> board) =>
      board.every((row) => !row.contains(0));

  /// Valid digits for an **empty** cell given current placements (row / column / box).
  static Set<int> candidatesFor(List<List<int>> board, int row, int col) {
    if (board[row][col] != 0) return {};
    final allowed = <int>{1, 2, 3, 4, 5, 6, 7, 8, 9};
    for (var i = 0; i < 9; i++) {
      final v = board[row][i];
      if (v != 0) allowed.remove(v);
    }
    for (var r = 0; r < 9; r++) {
      final v = board[r][col];
      if (v != 0) allowed.remove(v);
    }
    final br = (row ~/ 3) * 3;
    final bc = (col ~/ 3) * 3;
    for (var r = br; r < br + 3; r++) {
      for (var c = bc; c < bc + 3; c++) {
        final v = board[r][c];
        if (v != 0) allowed.remove(v);
      }
    }
    return allowed;
  }

  /// Naked single, else wrong user cell, else first empty (digit from [solution]).
  static ({int row, int col, int digit})? findAutoHintPlacement(
    List<List<int>> board,
    List<List<bool>> isFixed,
    List<List<int>> solution,
  ) {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (isFixed[r][c]) continue;
        if (board[r][c] != 0) continue;
        final cand = candidatesFor(board, r, c);
        if (cand.length == 1) {
          return (row: r, col: c, digit: cand.single);
        }
      }
    }
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (isFixed[r][c]) continue;
        final v = board[r][c];
        if (v != 0 && v != solution[r][c]) {
          return (row: r, col: c, digit: solution[r][c]);
        }
      }
    }
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (isFixed[r][c]) continue;
        if (board[r][c] == 0) {
          return (row: r, col: c, digit: solution[r][c]);
        }
      }
    }
    return null;
  }

  static bool _fillBoard(List<List<int>> board, Random rng) {
    for (var row = 0; row < 9; row++) {
      for (var col = 0; col < 9; col++) {
        if (board[row][col] == 0) {
          final nums = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle(rng);
          for (final num in nums) {
            if (_isValid(board, row, col, num)) {
              board[row][col] = num;
              if (_fillBoard(board, rng)) return true;
              board[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  static bool _isValid(
    List<List<int>> board,
    int row,
    int col,
    int num,
  ) {
    if (board[row].contains(num)) return false;

    for (var r = 0; r < 9; r++) {
      if (board[r][col] == num) return false;
    }

    final br = (row ~/ 3) * 3;
    final bc = (col ~/ 3) * 3;
    for (var r = br; r < br + 3; r++) {
      for (var c = bc; c < bc + 3; c++) {
        if (board[r][c] == num) return false;
      }
    }

    return true;
  }

  static bool _hasUniqueSolution(List<List<int>> board) {
    final copy = board.map((r) => List<int>.from(r)).toList();
    final counter = _Counter();
    _countSolutions(copy, counter);
    return counter.value == 1;
  }

  static void _countSolutions(List<List<int>> board, _Counter counter) {
    if (counter.value > 1) return;

    for (var row = 0; row < 9; row++) {
      for (var col = 0; col < 9; col++) {
        if (board[row][col] == 0) {
          for (var num = 1; num <= 9; num++) {
            if (_isValid(board, row, col, num)) {
              board[row][col] = num;
              _countSolutions(board, counter);
              board[row][col] = 0;
              if (counter.value > 1) return;
            }
          }
          return;
        }
      }
    }
    counter.increment();
  }
}

class _Counter {
  int value = 0;
  void increment() => value++;
}

/// Top-level for [compute]: [int] difficulty index, or [Map] with `d` and `seed`.
List<List<List<int>>> generatePuzzleInIsolate(Object arg) {
  if (arg is int) {
    final difficulty = Difficulty.values[arg];
    final rng = Random();
    final solution = SudokuEngine.generateSolution(rng);
    final puzzle = SudokuEngine.createPuzzle(solution, difficulty, rng);
    return [solution, puzzle];
  }
  final map = arg as Map<String, dynamic>;
  final difficulty = Difficulty.values[map['d'] as int];
  final seed = map['seed'] as int;
  final rng = Random(seed);
  final solution = SudokuEngine.generateSolution(rng);
  final puzzle = SudokuEngine.createPuzzle(solution, difficulty, rng);
  return [solution, puzzle];
}
