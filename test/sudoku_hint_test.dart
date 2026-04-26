import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/game_logic/sudoku_engine.dart';

void main() {
  group('candidatesFor', () {
    test('only one digit fits last gap in a row', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      for (var c = 0; c < 8; c++) {
        board[0][c] = c + 1;
      }
      expect(SudokuEngine.candidatesFor(board, 0, 8), {9});
    });
  });

  group('findAutoHintPlacement', () {
    test('naked single: first empty with one candidate', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      for (var c = 0; c < 8; c++) {
        board[0][c] = c + 1;
      }
      final isFixed = List.generate(
        9,
        (r) => List.generate(9, (c) => board[r][c] != 0),
      );
      final solution = List.generate(9, (_) => List.filled(9, 0));
      solution[0][8] = 9;

      final h = SudokuEngine.findAutoHintPlacement(board, isFixed, solution);
      expect(h, isNotNull);
      expect(h!.row, 0);
      expect(h.col, 8);
      expect(h.digit, 9);
    });

    test('wrong digit when grid is otherwise full', () {
      // Minimal valid completed grid (one of many).
      const sol = [
        [5, 3, 4, 6, 7, 8, 9, 1, 2],
        [6, 7, 2, 1, 9, 5, 3, 4, 8],
        [1, 9, 8, 3, 4, 2, 5, 6, 7],
        [8, 5, 9, 7, 6, 1, 4, 2, 3],
        [4, 2, 6, 8, 5, 3, 7, 9, 1],
        [7, 1, 3, 9, 2, 4, 8, 5, 6],
        [9, 6, 1, 5, 3, 7, 2, 8, 4],
        [2, 8, 7, 4, 1, 9, 6, 3, 5],
        [3, 4, 5, 2, 8, 6, 1, 7, 9],
      ];
      final board = sol.map((r) => List<int>.from(r)).toList();
      board[0][0] = 2; // wrong; should be 5
      final isFixed =
          List.generate(9, (_) => List.generate(9, (_) => true));
      isFixed[0][0] = false;

      final h = SudokuEngine.findAutoHintPlacement(
        board,
        isFixed,
        sol.map((r) => List<int>.from(r)).toList(),
      );
      expect(h, isNotNull);
      expect(h!.row, 0);
      expect(h.col, 0);
      expect(h.digit, 5);
    });
  });
}
