import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

/// Fade + slide-up entrance animation for a single element.
///
/// Wrap home / screen sections and give each an increasing [delay] to get a
/// staggered, alive reveal as the screen settles.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 18,
    this.duration = Motion.entrance,
  });

  final Widget child;
  final Duration delay;
  final double offset;
  final Duration duration;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _curved =
      CurvedAnimation(parent: _ctrl, curve: Motion.standard);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curved,
      builder: (context, child) => Opacity(
        opacity: _curved.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _curved.value) * widget.offset),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Wraps each child in an [Entrance] with an incremental delay, producing a
/// staggered reveal. Drop-in replacement for a Column's children list.
List<Widget> staggered(
  List<Widget> children, {
  Duration step = const Duration(milliseconds: 70),
  Duration start = const Duration(milliseconds: 40),
}) {
  return [
    for (var i = 0; i < children.length; i++)
      Entrance(
        delay: start + step * i,
        child: children[i],
      ),
  ];
}
