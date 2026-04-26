import 'package:flutter/material.dart';

/// Per-theme palette as a [ThemeExtension].
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.primaryLight,
    required this.pastel,
    required this.container,
    required this.dark,
    required this.surface,
    required this.pureWhite,
    required this.softWhite,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.shadow,
    required this.secondaryContainer,
    required this.tertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.outlineVariant,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.inversePrimary,
  });

  final Color primary;
  final Color primaryLight;
  final Color pastel;
  final Color container;
  final Color dark;

  final Color surface;
  final Color pureWhite;
  final Color softWhite;

  final Color onSurface;
  final Color onSurfaceVariant;

  final Color outline;
  final Color shadow;

  final Color secondaryContainer;
  final Color tertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color outlineVariant;

  final Color inverseSurface;
  final Color onInverseSurface;
  final Color inversePrimary;

  Color get cellSelected =>
      Color.alphaBlend(primary.withValues(alpha: 0.42), pureWhite);

  Color get cellSameNumber =>
      Color.alphaBlend(primary.withValues(alpha: 0.22), pureWhite);

  Color get cellHouseHighlight =>
      Color.alphaBlend(primary.withValues(alpha: 0.11), surface);

  Color get notePadBackground =>
      Color.alphaBlend(container.withValues(alpha: 0.65), pureWhite);

  Color get celebrationMid =>
      Color.lerp(container, pureWhite, 0.52) ?? container;

  Color get celebrationBottom => surface;

  List<Color> get titleShaderColors => [primary, dark, primaryLight];

  List<Color> confettiColors() => [
        primary,
        primaryLight,
        pastel,
        const Color(0xFFFFD700),
        const Color(0xFFFFC107),
        const Color(0xFFFF8F00),
        const Color(0xFFFFECB3),
        pureWhite,
        dark,
      ];

  @override
  AppColors copyWith({
    Color? primary,
    Color? primaryLight,
    Color? pastel,
    Color? container,
    Color? dark,
    Color? surface,
    Color? pureWhite,
    Color? softWhite,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? outline,
    Color? shadow,
    Color? secondaryContainer,
    Color? tertiary,
    Color? tertiaryContainer,
    Color? onTertiaryContainer,
    Color? outlineVariant,
    Color? inverseSurface,
    Color? onInverseSurface,
    Color? inversePrimary,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      pastel: pastel ?? this.pastel,
      container: container ?? this.container,
      dark: dark ?? this.dark,
      surface: surface ?? this.surface,
      pureWhite: pureWhite ?? this.pureWhite,
      softWhite: softWhite ?? this.softWhite,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      outline: outline ?? this.outline,
      shadow: shadow ?? this.shadow,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      tertiary: tertiary ?? this.tertiary,
      tertiaryContainer: tertiaryContainer ?? this.tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer ?? this.onTertiaryContainer,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      inverseSurface: inverseSurface ?? this.inverseSurface,
      onInverseSurface: onInverseSurface ?? this.onInverseSurface,
      inversePrimary: inversePrimary ?? this.inversePrimary,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    if (t == 0) return this;
    if (t == 1) return other;
    Color lc(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return AppColors(
      primary: lc(primary, other.primary),
      primaryLight: lc(primaryLight, other.primaryLight),
      pastel: lc(pastel, other.pastel),
      container: lc(container, other.container),
      dark: lc(dark, other.dark),
      surface: lc(surface, other.surface),
      pureWhite: lc(pureWhite, other.pureWhite),
      softWhite: lc(softWhite, other.softWhite),
      onSurface: lc(onSurface, other.onSurface),
      onSurfaceVariant: lc(onSurfaceVariant, other.onSurfaceVariant),
      outline: lc(outline, other.outline),
      shadow: lc(shadow, other.shadow),
      secondaryContainer: lc(secondaryContainer, other.secondaryContainer),
      tertiary: lc(tertiary, other.tertiary),
      tertiaryContainer: lc(tertiaryContainer, other.tertiaryContainer),
      onTertiaryContainer: lc(onTertiaryContainer, other.onTertiaryContainer),
      outlineVariant: lc(outlineVariant, other.outlineVariant),
      inverseSurface: lc(inverseSurface, other.inverseSurface),
      onInverseSurface: lc(onInverseSurface, other.onInverseSurface),
      inversePrimary: lc(inversePrimary, other.inversePrimary),
    );
  }
}

extension AppThemeColors on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
