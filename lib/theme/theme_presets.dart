import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Global light/dark appearance (persisted). Separate from [AppThemeId] palette choice.
enum AppBrightness {
  light,
  dark;
}

enum AppThemeId {
  sakura,
  ocean,
  forest,
  sunset,
  lavender,
  midnight,
  honey,
  wine,
  neon;

  String get label => switch (this) {
        sakura => 'Sakura',
        ocean => 'Ocean',
        forest => 'Forest',
        sunset => 'Sunset',
        lavender => 'Lavender',
        midnight => 'Midnight',
        honey => 'Honey',
        wine => 'Wine',
        neon => 'Neon',
      };

  String get subtitle => switch (this) {
        sakura => 'Pink & white',
        ocean => 'Teal & sea',
        forest => 'Green & nature',
        sunset => 'Coral & warm tones',
        lavender => 'Purple & lavender',
        midnight => 'Navy & cool blue',
        honey => 'Amber & gold',
        wine => 'Burgundy & rose',
        neon => 'Electric & dark',
      };
}

AppColors _appColorsFor(AppThemeId id) => switch (id) {
      AppThemeId.sakura => _sakura,
      AppThemeId.ocean => _ocean,
      AppThemeId.forest => _forest,
      AppThemeId.sunset => _sunset,
      AppThemeId.lavender => _lavender,
      AppThemeId.midnight => _midnight,
      AppThemeId.honey => _honey,
      AppThemeId.wine => _wine,
      AppThemeId.neon => _neon,
    };

/// Resolves palette for theme + appearance. [AppThemeId.neon] uses [_neon] / [_neonLight].
/// With Pro neon effects on, [applyNeonSkin] further boosts saturation on top (light & dark).
AppColors resolveAppColors(AppThemeId id, AppBrightness brightness) {
  if (id == AppThemeId.neon) {
    return brightness == AppBrightness.dark ? _neon : _neonLight;
  }
  final light = _appColorsFor(id);
  if (brightness == AppBrightness.light) return light;
  return darkVariantFromLight(light);
}

AppColors darkVariantFromLight(AppColors l) {
  if (l.isDark) return l;
  final base = l.inverseSurface;
  final card = Color.lerp(base, l.container, 0.22) ?? base;
  final soft = Color.lerp(base, l.container, 0.16) ?? base;
  return l.copyWith(
    isDark: true,
    surface: base,
    pureWhite: card,
    softWhite: soft,
    onSurface: l.onInverseSurface,
    // Bumped from 0.75 → 0.92 so numpad digits and notes are clearly visible
    onSurfaceVariant: Color.alphaBlend(
      l.onInverseSurface.withValues(alpha: 0.92),
      base,
    ),
    // Increased from 0.48 → 0.65 so numpad buttons stand out from surface
    container: Color.alphaBlend(l.container.withValues(alpha: 0.65), base),
    secondaryContainer: Color.alphaBlend(
      l.secondaryContainer.withValues(alpha: 0.36),
      base,
    ),
    tertiaryContainer: Color.alphaBlend(
      l.tertiaryContainer.withValues(alpha: 0.28),
      base,
    ),
    // Increased from 0.55 → 0.75 so grid lines are clearly visible in dark
    outline: Color.alphaBlend(l.outline.withValues(alpha: 0.75), base),
    outlineVariant:
        Color.alphaBlend(l.outlineVariant.withValues(alpha: 0.55), base),
    inverseSurface: l.surface,
    onInverseSurface: l.onSurface,
    inversePrimary: l.inversePrimary,
    primary: l.primaryLight,
    primaryLight: Color.lerp(l.primaryLight, l.pastel, 0.45) ?? l.primaryLight,
    pastel: Color.alphaBlend(l.pastel.withValues(alpha: 0.45), base),
    dark: l.primary,
    tertiary: l.tertiary,
    onTertiaryContainer: l.onTertiaryContainer,
  );
}

// --- Neon skin helpers (palette hue → saturated “tube” colors) ---

Color _neonTube(Color seed, {double lightness = 0.54}) {
  final h = HSLColor.fromColor(seed);
  return h
      .withSaturation((h.saturation + 0.22).clamp(0.0, 1.0))
      .withLightness(lightness.clamp(0.4, 0.62))
      .toColor();
}

Color _neonTubeLight(Color seed) {
  final h = HSLColor.fromColor(seed);
  return h
      .withSaturation((h.saturation + 0.15).clamp(0.0, 1.0))
      .withLightness((h.lightness + 0.1).clamp(0.48, 0.78))
      .toColor();
}

Color _neonAccent(Color seed) {
  final h = HSLColor.fromColor(seed);
  return h
      .withSaturation((h.saturation + 0.18).clamp(0.0, 1.0))
      .withLightness(0.52.clamp(0.42, 0.68))
      .toColor();
}

AppColors _neonSkinDarkCanvas(AppColors resolved) {
  final neonPrimary = _neonTube(resolved.primary);
  final neonPrimaryLight = _neonTubeLight(resolved.primaryLight);
  final neonTertiary = _neonAccent(resolved.tertiary);

  const neutral = Color(0xFF0A0B10);
  final surface =
      Color.alphaBlend(resolved.primary.withValues(alpha: 0.14), neutral);
  final pureWhite = Color.alphaBlend(
    resolved.primary.withValues(alpha: 0.09),
    const Color(0xFF11131C),
  );
  final softWhite = Color.alphaBlend(
    resolved.primary.withValues(alpha: 0.11),
    const Color(0xFF13151F),
  );

  final onSurface =
      Color.lerp(resolved.onSurface, Colors.white, 0.14) ?? resolved.onSurface;
  final onSurfaceVariant = Color.alphaBlend(
    neonPrimaryLight.withValues(alpha: 0.38),
    Color.alphaBlend(onSurface.withValues(alpha: 0.88), surface),
  );

  final container =
      Color.alphaBlend(neonPrimary.withValues(alpha: 0.2), surface);
  final secondaryContainer =
      Color.alphaBlend(neonPrimaryLight.withValues(alpha: 0.16), surface);
  final tertiaryContainer =
      Color.alphaBlend(neonTertiary.withValues(alpha: 0.14), surface);

  final outline =
      Color.alphaBlend(neonPrimary.withValues(alpha: 0.48), surface);
  final outlineVariant =
      Color.alphaBlend(neonPrimary.withValues(alpha: 0.28), surface);
  final pastel =
      Color.alphaBlend(neonPrimaryLight.withValues(alpha: 0.52), surface);
  final darkDeep = HSLColor.fromColor(neonPrimary).withLightness(0.22).toColor();
  final onTertiary =
      Color.lerp(onSurface, neonTertiary, 0.72) ?? neonTertiary;

  return resolved.copyWith(
    isDark: true,
    primary: neonPrimary,
    primaryLight: neonPrimaryLight,
    pastel: pastel,
    container: container,
    dark: darkDeep,
    surface: surface,
    pureWhite: pureWhite,
    softWhite: softWhite,
    onSurface: onSurface,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    shadow: neonPrimary.withValues(alpha: 0.38),
    secondaryContainer: secondaryContainer,
    tertiary: neonTertiary,
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: onTertiary,
    inverseSurface: resolved.surface,
    onInverseSurface: resolved.onSurface,
    inversePrimary: neonPrimaryLight,
  );
}

/// Light canvas: bright surfaces with boosted neon primaries (all presets + Neon light).
AppColors _neonSkinLightCanvas(AppColors resolved) {
  final neonPrimary = _neonTube(resolved.primary, lightness: 0.48);
  final neonPrimaryLight = _neonTubeLight(resolved.primaryLight);
  final neonTertiary = _neonAccent(resolved.tertiary);

  final surface =
      Color.alphaBlend(neonPrimary.withValues(alpha: 0.09), resolved.surface);
  final pureWhite =
      Color.alphaBlend(neonPrimary.withValues(alpha: 0.05), resolved.pureWhite);
  final softWhite =
      Color.alphaBlend(neonPrimary.withValues(alpha: 0.06), resolved.softWhite);
  final container =
      Color.alphaBlend(neonPrimary.withValues(alpha: 0.16), resolved.container);
  final secondaryContainer = Color.alphaBlend(
    neonPrimaryLight.withValues(alpha: 0.14),
    resolved.secondaryContainer,
  );
  final tertiaryContainer = Color.alphaBlend(
    neonTertiary.withValues(alpha: 0.12),
    resolved.tertiaryContainer,
  );
  final pastel =
      Color.lerp(resolved.pastel, neonPrimaryLight, 0.38) ?? resolved.pastel;
  final outline =
      Color.lerp(resolved.outline, neonPrimary, 0.5) ?? resolved.outline;
  final outlineVariant = Color.lerp(
        resolved.outlineVariant,
        neonPrimaryLight,
        0.38,
      ) ??
      resolved.outlineVariant;
  final onSurfaceVariant = Color.lerp(
        resolved.onSurfaceVariant,
        neonPrimary,
        0.12,
      ) ??
      resolved.onSurfaceVariant;
  final darkDeep =
      HSLColor.fromColor(neonPrimary).withLightness(0.30).toColor();

  return resolved.copyWith(
    isDark: false,
    primary: neonPrimary,
    primaryLight: neonPrimaryLight,
    pastel: pastel,
    tertiary: neonTertiary,
    surface: surface,
    pureWhite: pureWhite,
    softWhite: softWhite,
    container: container,
    secondaryContainer: secondaryContainer,
    tertiaryContainer: tertiaryContainer,
    outline: outline,
    outlineVariant: outlineVariant,
    shadow: neonPrimary.withValues(alpha: 0.28),
    dark: darkDeep,
    onSurfaceVariant: onSurfaceVariant,
    inversePrimary: neonPrimaryLight,
  );
}

/// Pro neon chrome: appearance-aware. Light keeps a bright UI with saturated hues;
/// dark uses the cyber canvas. [AppThemeId.neon] + dark keeps [_neon] unchanged.
AppColors applyNeonSkin(
  AppColors resolved, {
  required AppThemeId themeId,
  required AppBrightness brightness,
}) {
  if (themeId == AppThemeId.neon && brightness == AppBrightness.dark) {
    return resolved;
  }
  if (brightness == AppBrightness.light) {
    return _neonSkinLightCanvas(resolved);
  }
  return _neonSkinDarkCanvas(resolved);
}

const _sakura = AppColors(
  primary: Color(0xFFE91E8C),
  primaryLight: Color(0xFFFF69B4),
  pastel: Color(0xFFF8BBD9),
  container: Color(0xFFFFE4F0),
  dark: Color(0xFFC2185B),
  surface: Color(0xFFFFF5F9),
  pureWhite: Color(0xFFFFFFFF),
  softWhite: Color(0xFFFAFAFA),
  onSurface: Color(0xFF1C0A14),
  onSurfaceVariant: Color(0xFF5D4A52),
  outline: Color(0xFFE8B4CC),
  shadow: Color(0x1AE91E8C),
  secondaryContainer: Color(0xFFFFD6EA),
  tertiary: Color(0xFFB06090),
  tertiaryContainer: Color(0xFFFFD8EE),
  onTertiaryContainer: Color(0xFF3A0025),
  outlineVariant: Color(0xFFF3D0E2),
  inverseSurface: Color(0xFF341126),
  onInverseSurface: Color(0xFFFFECF3),
  inversePrimary: Color(0xFFF8BBD9),
);

const _ocean = AppColors(
  primary: Color(0xFF00695C),
  primaryLight: Color(0xFF26A69A),
  pastel: Color(0xFFB2DFDB),
  container: Color(0xFFE0F2F1),
  dark: Color(0xFF004D40),
  surface: Color(0xFFF2F9F8),
  pureWhite: Color(0xFFFFFFFF),
  softWhite: Color(0xFFF5FAF9),
  onSurface: Color(0xFF0C1F1D),
  onSurfaceVariant: Color(0xFF4A5E5A),
  outline: Color(0xFFB0C9C4),
  shadow: Color(0x1A00695C),
  secondaryContainer: Color(0xFFB2EBF2),
  tertiary: Color(0xFF00838F),
  tertiaryContainer: Color(0xFFE0F7FA),
  onTertiaryContainer: Color(0xFF004D56),
  outlineVariant: Color(0xFFD0E5E2),
  inverseSurface: Color(0xFF0D2C28),
  onInverseSurface: Color(0xFFE0F2F1),
  inversePrimary: Color(0xFF80CBC4),
);

const _forest = AppColors(
  primary: Color(0xFF2E7D32),
  primaryLight: Color(0xFF66BB6A),
  pastel: Color(0xFFC8E6C9),
  container: Color(0xFFE8F5E9),
  dark: Color(0xFF1B5E20),
  surface: Color(0xFFF5FAF5),
  pureWhite: Color(0xFFFFFFFF),
  softWhite: Color(0xFFF8FAF8),
  onSurface: Color(0xFF111F12),
  onSurfaceVariant: Color(0xFF4D5A4E),
  outline: Color(0xFFB8D4B9),
  shadow: Color(0x1A2E7D32),
  secondaryContainer: Color(0xFFDCEDC8),
  tertiary: Color(0xFF558B2F),
  tertiaryContainer: Color(0xFFF1F8E9),
  onTertiaryContainer: Color(0xFF33691E),
  outlineVariant: Color(0xFFDDE8DD),
  inverseSurface: Color(0xFF142A16),
  onInverseSurface: Color(0xFFE8F5E9),
  inversePrimary: Color(0xFFA5D6A7),
);

const _sunset = AppColors(
  primary: Color(0xFFD84315),
  primaryLight: Color(0xFFFF8A65),
  pastel: Color(0xFFFFCCBC),
  container: Color(0xFFFBE9E7),
  dark: Color(0xFFBF360C),
  surface: Color(0xFFFFFAF8),
  pureWhite: Color(0xFFFFFFFF),
  softWhite: Color(0xFFFAF7F5),
  onSurface: Color(0xFF1A0F0C),
  onSurfaceVariant: Color(0xFF5D4E48),
  outline: Color(0xFFFFAB91),
  shadow: Color(0x1AD84315),
  secondaryContainer: Color(0xFFFFE0B2),
  tertiary: Color(0xFFE65100),
  tertiaryContainer: Color(0xFFFFF3E0),
  onTertiaryContainer: Color(0xFF4E2608),
  outlineVariant: Color(0xFFFFE0D6),
  inverseSurface: Color(0xFF2D1810),
  onInverseSurface: Color(0xFFFFEDE7),
  inversePrimary: Color(0xFFFFAB91),
);

const _lavender = AppColors(
  primary: Color(0xFF5E35B1),
  primaryLight: Color(0xFF9575CD),
  pastel: Color(0xFFD1C4E9),
  container: Color(0xFFEDE7F6),
  dark: Color(0xFF4527A0),
  surface: Color(0xFFF8F6FC),
  pureWhite: Color(0xFFFFFFFF),
  softWhite: Color(0xFFF9F7FB),
  onSurface: Color(0xFF140A1F),
  onSurfaceVariant: Color(0xFF5D5266),
  outline: Color(0xFFD1C4E9),
  shadow: Color(0x1A5E35B1),
  secondaryContainer: Color(0xFFE1BEE7),
  tertiary: Color(0xFF7E57C2),
  tertiaryContainer: Color(0xFFF3E5F5),
  onTertiaryContainer: Color(0xFF311B4D),
  outlineVariant: Color(0xFFE8DEF5),
  inverseSurface: Color(0xFF1E1030),
  onInverseSurface: Color(0xFFF3E5F5),
  inversePrimary: Color(0xFFB39DDB),
);

const _midnight = AppColors(
  primary: Color(0xFF1E3A5F),
  primaryLight: Color(0xFF3D6A9E),
  pastel: Color(0xFFB8D4EB),
  container: Color(0xFFE4EDF5),
  dark: Color(0xFF0F2840),
  surface: Color(0xFFF4F7FB),
  pureWhite: Color(0xFFFFFFFF),
  softWhite: Color(0xFFF7F9FC),
  onSurface: Color(0xFF0D1522),
  onSurfaceVariant: Color(0xFF4A5568),
  outline: Color(0xFFC1CEDD),
  shadow: Color(0x221E3A5F),
  secondaryContainer: Color(0xFFD0E3F5),
  tertiary: Color(0xFF5C6BC0),
  tertiaryContainer: Color(0xFFE8EAF6),
  onTertiaryContainer: Color(0xFF1A237E),
  outlineVariant: Color(0xFFE2E9F2),
  inverseSurface: Color(0xFF0C1828),
  onInverseSurface: Color(0xFFE4EDF5),
  inversePrimary: Color(0xFF90CAF9),
);

const _honey = AppColors(
  primary: Color(0xFFB8860B),
  primaryLight: Color(0xFFE6A819),
  pastel: Color(0xFFFFE082),
  container: Color(0xFFFFF8E6),
  dark: Color(0xFF8B6914),
  surface: Color(0xFFFFFCF5),
  pureWhite: Color(0xFFFFFFFF),
  softWhite: Color(0xFFFFFAF3),
  onSurface: Color(0xFF1C1408),
  onSurfaceVariant: Color(0xFF5D5340),
  outline: Color(0xFFE8D4A8),
  shadow: Color(0x22B8860B),
  secondaryContainer: Color(0xFFFFECB3),
  tertiary: Color(0xFFD4A017),
  tertiaryContainer: Color(0xFFFFF3CD),
  onTertiaryContainer: Color(0xFF4A3A0A),
  outlineVariant: Color(0xFFF5EAD0),
  inverseSurface: Color(0xFF2A2210),
  onInverseSurface: Color(0xFFFFF8E6),
  inversePrimary: Color(0xFFFFD54F),
);

const _wine = AppColors(
  primary: Color(0xFF6D1B3E),
  primaryLight: Color(0xFFB23A5F),
  pastel: Color(0xFFF5C6D6),
  container: Color(0xFFFCE8EF),
  dark: Color(0xFF4A1029),
  surface: Color(0xFFFFFAFB),
  pureWhite: Color(0xFFFFFFFF),
  softWhite: Color(0xFFFCF8F9),
  onSurface: Color(0xFF1A0A10),
  onSurfaceVariant: Color(0xFF5D4550),
  outline: Color(0xFFE8B8C8),
  shadow: Color(0x226D1B3E),
  secondaryContainer: Color(0xFFFFD6E0),
  tertiary: Color(0xFFAD1457),
  tertiaryContainer: Color(0xFFFCE4EC),
  onTertiaryContainer: Color(0xFF4A0D24),
  outlineVariant: Color(0xFFF5D6E0),
  inverseSurface: Color(0xFF2A1018),
  onInverseSurface: Color(0xFFFCE8EF),
  inversePrimary: Color(0xFFF48FB1),
);

const _neon = AppColors(
  isDark: true,
  primary: Color(0xFF00E5FF),
  primaryLight: Color(0xFF4DD0E1),
  pastel: Color(0xFF80DEEA),
  container: Color(0xFF0D2530),
  dark: Color(0xFF0097A7),
  surface: Color(0xFF07090E),
  pureWhite: Color(0xFF0B1520),
  softWhite: Color(0xFF0E1C2A),
  onSurface: Color(0xFFCCEEF4),
  onSurfaceVariant: Color(0xFF6AAFBC),
  outline: Color(0xFF1A3540),
  shadow: Color(0x3300E5FF),
  secondaryContainer: Color(0xFF0A1C28),
  tertiary: Color(0xFF64FF47),
  tertiaryContainer: Color(0xFF071A05),
  onTertiaryContainer: Color(0xFF64FF47),
  outlineVariant: Color(0xFF152A35),
  inverseSurface: Color(0xFFCCEEF4),
  onInverseSurface: Color(0xFF07090E),
  inversePrimary: Color(0xFF006064),
);

/// Light-room variant of the neon cyber palette ([AppBrightness.light] + neon theme).
const _neonLight = AppColors(
  isDark: false,
  primary: Color(0xFF00ACC1),
  primaryLight: Color(0xFF26C6DA),
  pastel: Color(0xFFB2EBF2),
  container: Color(0xFFE0F7FA),
  dark: Color(0xFF00838F),
  surface: Color(0xFFF2FDFF),
  pureWhite: Color(0xFFFFFFFF),
  softWhite: Color(0xFFEEFBFC),
  onSurface: Color(0xFF002329),
  onSurfaceVariant: Color(0xFF006978),
  outline: Color(0xFFB2EBF2),
  shadow: Color(0x2200ACC1),
  secondaryContainer: Color(0xFFDFFFE8),
  tertiary: Color(0xFF00C853),
  tertiaryContainer: Color(0xFFE8F5E9),
  onTertiaryContainer: Color(0xFF1B5E20),
  outlineVariant: Color(0xFFD6F5F7),
  inverseSurface: Color(0xFF00424A),
  onInverseSurface: Color(0xFFE0F7FA),
  inversePrimary: Color(0xFF00E5FF),
);
