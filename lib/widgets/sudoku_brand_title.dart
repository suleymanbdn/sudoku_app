import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class SudokuBrandTitle extends StatelessWidget {
  const SudokuBrandTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Text(
      'Sudoku',
      style: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: c.primary,
      ),
    );
  }
}
