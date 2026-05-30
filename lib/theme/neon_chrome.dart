import 'package:flutter/material.dart';

import 'app_colors.dart';

/// When [enabled], surfaces can add glow via [withNeonIf] and global [ThemeData] tweaks apply.
@immutable
class NeonChrome extends ThemeExtension<NeonChrome> {
  const NeonChrome({required this.enabled});

  final bool enabled;

  static NeonChrome? maybeOf(BuildContext context) =>
      Theme.of(context).extension<NeonChrome>();

  static List<BoxShadow> glowShadows(AppColors c) => [
        BoxShadow(
          color: c.primary.withValues(alpha: 0.28),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: c.primaryLight.withValues(alpha: 0.16),
          blurRadius: 26,
          spreadRadius: -4,
        ),
        BoxShadow(
          color: c.tertiary.withValues(alpha: 0.14),
          blurRadius: 20,
          spreadRadius: -3,
          offset: const Offset(0, 8),
        ),
      ];

  @override
  NeonChrome copyWith({bool? enabled}) =>
      NeonChrome(enabled: enabled ?? this.enabled);

  @override
  NeonChrome lerp(ThemeExtension<NeonChrome>? other, double t) {
    if (other is! NeonChrome) return this;
    return NeonChrome(enabled: t < 0.5 ? enabled : other.enabled);
  }
}

extension NeonBoxDecoration on BoxDecoration {
  BoxDecoration withNeonIf(BuildContext context, AppColors c) {
    final active = NeonChrome.maybeOf(context)?.enabled ?? false;
    if (!active) return this;
    return BoxDecoration(
      color: color,
      image: image,
      gradient: gradient,
      borderRadius: borderRadius,
      border: border,
      boxShadow: [...?boxShadow, ...NeonChrome.glowShadows(c)],
      shape: shape,
      backgroundBlendMode: backgroundBlendMode,
    );
  }
}
