import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Shared “Sudoku Puzzle” title on home and game screens.
class SudokuBrandTitle extends StatelessWidget {
  const SudokuBrandTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Sudoku ',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: c.primary,
            ),
          ),
          TextSpan(
            text: 'Puzzle',
            style: GoogleFonts.dancingScript(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: c.dark,
            ),
          ),
        ],
      ),
    );
  }
}
