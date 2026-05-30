import 'package:flutter/widgets.dart';

import '../game_logic/sudoku_engine.dart';
import 'app_localizations.dart';

/// Localized display name for a [Difficulty]. The engine stays UI-agnostic;
/// this resolves the name from the active locale at the widget layer.
extension DifficultyL10n on Difficulty {
  String localizedLabel(BuildContext context) {
    final l = AppLocalizations.of(context);
    return switch (this) {
      Difficulty.easy => l.difficultyEasy,
      Difficulty.medium => l.difficultyMedium,
      Difficulty.hard => l.difficultyHard,
      Difficulty.expert => l.difficultyExpert,
    };
  }
}
