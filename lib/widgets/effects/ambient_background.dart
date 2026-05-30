import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A slow, living gradient backdrop — soft glowing blobs that drift behind
/// the content. This is the main "alive" signal of the redesigned UI.
///
/// Light themes get a subtle tinted aurora; dark themes get a slightly
/// stronger glow. Uses radial gradients (no blur filter) so it stays cheap
/// even while animating continuously.
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({
    super.key,
    required this.colors,
    required this.dark,
    this.intensity = 1.0,
    this.child,
  });

  final AppColors colors;

  /// Light vs dark behaviour. Pass the brightness from the theme provider.
  final bool dark;
  final double intensity;
  final Widget? child;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 26),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) => CustomPaint(
                painter: _AmbientPainter(
                  t: _ctrl.value,
                  colors: c,
                  dark: widget.dark,
                  intensity: widget.intensity,
                ),
              ),
            ),
          ),
        ),
        if (widget.child != null) Positioned.fill(child: widget.child!),
      ],
    );
  }
}

class _Blob {
  const _Blob({
    required this.color,
    required this.alpha,
    required this.baseX,
    required this.baseY,
    required this.driftX,
    required this.driftY,
    required this.radius,
    required this.speed,
    required this.phase,
  });

  final Color color;
  final double alpha;
  final double baseX; // 0..1 of width
  final double baseY; // 0..1 of height
  final double driftX; // 0..1 of width
  final double driftY;
  final double radius; // 0..1 of shortest side
  final double speed; // cycles over one full t
  final double phase;
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter({
    required this.t,
    required this.colors,
    required this.dark,
    required this.intensity,
  });

  final double t;
  final AppColors colors;
  final bool dark;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    // Base fill so the backdrop is fully opaque.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = colors.surface,
    );

    // Per-theme blob recipe. Dark themes glow a touch brighter; light themes
    // stay subtle so content keeps full contrast.
    final blobs = <_Blob>[
      _Blob(
        color: dark ? colors.primary : colors.primaryLight,
        alpha: (dark ? 0.20 : 0.14) * intensity,
        baseX: 0.18,
        baseY: 0.12,
        driftX: 0.10,
        driftY: 0.07,
        radius: dark ? 0.62 : 0.70,
        speed: 1,
        phase: 0,
      ),
      _Blob(
        color: dark ? colors.primaryLight : colors.pastel,
        alpha: (dark ? 0.16 : 0.18) * intensity,
        baseX: 0.86,
        baseY: 0.30,
        driftX: 0.09,
        driftY: 0.10,
        radius: dark ? 0.58 : 0.66,
        speed: 1,
        phase: 2.1,
      ),
      _Blob(
        color: dark ? colors.dark : colors.primary,
        alpha: (dark ? 0.18 : 0.08) * intensity,
        baseX: 0.50,
        baseY: 0.92,
        driftX: 0.12,
        driftY: 0.08,
        radius: dark ? 0.66 : 0.74,
        speed: 1,
        phase: 4.0,
      ),
    ];

    final twoPi = 2 * math.pi;
    final shortest = math.min(size.width, size.height);

    for (final b in blobs) {
      final cx = (b.baseX + b.driftX * math.sin(twoPi * t * b.speed + b.phase)) *
          size.width;
      final cy = (b.baseY +
              b.driftY * math.cos(twoPi * t * b.speed + b.phase * 1.3)) *
          size.height;
      final r = b.radius * shortest;
      final center = Offset(cx, cy);

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            b.color.withValues(alpha: b.alpha),
            b.color.withValues(alpha: 0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r));
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter old) =>
      old.t != t ||
      old.colors != colors ||
      old.dark != dark ||
      old.intensity != intensity;
}
