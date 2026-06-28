import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/motion.dart';

/// Wraps any tappable [child] to add a subtle scale-down + light haptic on
/// press. Built on [Listener] so it does **not** intercept the gesture — an
/// inner `InkWell`/`onTap` still receives the tap and shows its ripple.
///
/// Collapses to the plain child when reduced motion is requested.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.scale = 0.97,
    this.haptic = true,
  });

  final Widget child;
  final double scale;
  final bool haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    if (!AppMotion.on(context)) return widget.child;
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: (_) {
        if (widget.haptic) HapticFeedback.lightImpact();
        _set(true);
      },
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: AppMotion.fast,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
