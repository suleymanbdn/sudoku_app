import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../game_logic/sudoku_engine.dart';
import '../models/game_state.dart';

const kActiveGamePrefsKey = 'active_game_v1';

/// Clears saved in-progress game (call when starting a new match or after win/loss).
Future<void> clearActiveGameSave(SharedPreferences prefs) async {
  await prefs.remove(kActiveGamePrefsKey);
}

/// Restores [GameState] for Continue after app restart, or null.
GameState? tryLoadActiveGame(SharedPreferences prefs) {
  final raw = prefs.getString(kActiveGamePrefsKey);
  if (raw == null || raw.isEmpty) return null;
  try {
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic>) return null;
    return _decode(json);
  } catch (_) {
    return null;
  }
}

Future<void> saveActiveGame(SharedPreferences prefs, GameState state) async {
  if (state.status != GameStatus.playing &&
      state.status != GameStatus.paused) {
    return;
  }
  if (state.solution.isEmpty || state.currentBoard.isEmpty) return;
  final raw = jsonEncode(_encode(state));
  await prefs.setString(kActiveGamePrefsKey, raw);
}

Map<String, dynamic> _encode(GameState s) => {
      'v': 1,
      'difficulty': s.difficulty.index,
      'solution': s.solution.map((r) => [...r]).toList(),
      'initialPuzzle': s.initialPuzzle.map((r) => [...r]).toList(),
      'currentBoard': s.currentBoard.map((r) => [...r]).toList(),
      'isFixed': s.isFixed
          .map((r) => r.map((b) => b ? 1 : 0).toList())
          .toList(),
      'errorCells': s.errorCells.toList(),
      'mistakeCount': s.mistakeCount,
      'hintsRemaining': s.hintsRemaining,
      'status': s.status.name,
      'selectedRow': s.selectedRow,
      'selectedCol': s.selectedCol,
      'elapsedSeconds': s.elapsedSeconds,
      'notes': s.notes
          .map(
            (row) => row
                .map((set) => (set.toList()..sort()).toList())
                .toList(),
          )
          .toList(),
      'noteMode': s.noteMode,
      'isDuel': s.isDuel,
      'duelRoomCode': s.duelRoomCode,
      'duelIsHost': s.duelIsHost,
    };

GameState? _decode(Map<String, dynamic> j) {
  if (j['v'] != 1) return null;
  final d = j['difficulty'];
  if (d is! int || d < 0 || d >= Difficulty.values.length) return null;

  GameStatus? st;
  final sn = j['status'];
  if (sn is String) {
    for (final e in GameStatus.values) {
      if (e.name == sn) {
        st = e;
        break;
      }
    }
  }
  if (st != GameStatus.playing && st != GameStatus.paused) return null;
  final status = st!;

  List<List<int>>? grid(String key) {
    final v = j[key];
    if (v is! List<dynamic>) return null;
    if (v.length != 9) return null;
    final out = <List<int>>[];
    for (final row in v) {
      if (row is! List<dynamic> || row.length != 9) return null;
      final ints = <int>[];
      for (final x in row) {
        if (x is! int || x < 0 || x > 9) return null;
        ints.add(x);
      }
      out.add(ints);
    }
    return out;
  }

  final solution = grid('solution');
  final initialPuzzle = grid('initialPuzzle');
  final currentBoard = grid('currentBoard');
  if (solution == null || initialPuzzle == null || currentBoard == null) {
    return null;
  }

  final fixRaw = j['isFixed'];
  if (fixRaw is! List<dynamic> || fixRaw.length != 9) return null;
  final isFixed = <List<bool>>[];
  for (final row in fixRaw) {
    if (row is! List<dynamic> || row.length != 9) return null;
    final br = <bool>[];
    for (final x in row) {
      if (x is! int || (x != 0 && x != 1)) return null;
      br.add(x == 1);
    }
    isFixed.add(br);
  }

  final ec = j['errorCells'];
  if (ec is! List<dynamic>) return null;
  final errorCells = <String>{};
  for (final e in ec) {
    if (e is String) errorCells.add(e);
  }

  final mc = j['mistakeCount'];
  final hr = j['hintsRemaining'];
  final sr = j['selectedRow'];
  final sc = j['selectedCol'];
  final es = j['elapsedSeconds'];
  if (mc is! int || hr is! int || sr is! int || sc is! int || es is! int) {
    return null;
  }
  if (mc < 0 || hr < 0 || es < 0) return null;
  if (sr < -1 || sr > 8 || sc < -1 || sc > 8) return null;

  final notesRaw = j['notes'];
  if (notesRaw is! List<dynamic> || notesRaw.length != 9) return null;
  final notes = <List<Set<int>>>[];
  for (final row in notesRaw) {
    if (row is! List<dynamic> || row.length != 9) return null;
    final nr = <Set<int>>[];
    for (final cell in row) {
      if (cell is! List<dynamic>) return null;
      final s = <int>{};
      for (final x in cell) {
        if (x is int && x >= 1 && x <= 9) s.add(x);
      }
      nr.add(s);
    }
    notes.add(nr);
  }

  final nm = j['noteMode'];
  if (nm is! bool) return null;
  final isDuel = j['isDuel'];
  if (isDuel is! bool) return null;
  final duelHost = j['duelIsHost'];
  if (duelHost is! bool) return null;
  final duelCode = j['duelRoomCode'];
  final String? room = duelCode is String ? duelCode : null;

  return GameState(
    difficulty: Difficulty.values[d],
    solution: solution,
    initialPuzzle: initialPuzzle,
    currentBoard: currentBoard,
    isFixed: isFixed,
    errorCells: errorCells,
    mistakeCount: mc,
    hintsRemaining: hr,
    status: status,
    selectedRow: sr,
    selectedCol: sc,
    elapsedSeconds: es,
    notes: notes,
    noteMode: nm,
    isDuel: isDuel,
    duelRoomCode: room,
    duelIsHost: duelHost,
  );
}
