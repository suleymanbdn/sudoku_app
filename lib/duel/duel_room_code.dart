import '../game_logic/sudoku_engine.dart';

/// Encodes [Difficulty] + 32-bit [seed] as a shareable room id (same = same puzzle).
class DuelRoomCode {
  DuelRoomCode._();

  static const _prefix = <Difficulty, String>{
    Difficulty.easy: 'E',
    Difficulty.medium: 'M',
    Difficulty.hard: 'H',
    Difficulty.expert: 'X',
  };

  static String encode(Difficulty difficulty, int seed) {
    final p = _prefix[difficulty]!;
    final u = seed.toUnsigned(32);
    return '$p${u.toRadixString(16).toUpperCase().padLeft(8, '0')}';
  }

  /// Returns null if invalid.
  static (Difficulty difficulty, int seed)? decode(String raw) {
    final s = raw.trim().toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    if (s.length < 9) return null;
    final letter = s[0];
    Difficulty? difficulty;
    for (final e in _prefix.entries) {
      if (e.value == letter) {
        difficulty = e.key;
        break;
      }
    }
    if (difficulty == null) return null;
    final hex = s.substring(1, 9);
    final seed = int.tryParse(hex, radix: 16);
    if (seed == null) return null;
    return (difficulty, seed);
  }
}
