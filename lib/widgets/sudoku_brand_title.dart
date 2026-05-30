import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/neon_chrome.dart';

/// Launcher / branding asset (512×512, bundled for in-app header).
const String kSudokuLogoAsset = 'branding/app_icon.png';

/// Grid logo mark; [height] sets layout size (width scales with aspect ratio).
class SudokuLogoMark extends StatelessWidget {
  const SudokuLogoMark({
    super.key,
    required this.height,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    final neon = NeonChrome.maybeOf(context)?.enabled ?? false;
    final img = Image.asset(
      kSudokuLogoAsset,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Sudoku',
    );
    if (!neon) return img;
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: context.appColors.primary.withValues(alpha: 0.35),
            blurRadius: 10,
            spreadRadius: -2,
          ),
        ],
      ),
      child: img,
    );
  }
}

/// Compact title for toolbars — logo only (wordmark removed in favor of new mark).
class SudokuBrandTitle extends StatelessWidget {
  const SudokuBrandTitle({super.key});

  @override
  Widget build(BuildContext context) => const SudokuLogoMark(height: 26);
}
