import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

/// The app's central motion system.
///
/// One place for timing/curve tokens, a reduce-motion gate, the reusable
/// entrance idiom ([RevealX] / [RevealListX]) and route-transition factories.
/// The character is deliberately *lively* (a little overshoot/spring) but every
/// helper collapses to an instant final state when the platform requests
/// reduced motion, which also keeps `pumpAndSettle` tests deterministic.
class AppMotion {
  AppMotion._();

  // Durations.
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration entrance = Duration(milliseconds: 420);
  static const Duration fill = Duration(milliseconds: 900);
  static const Duration stagger = Duration(milliseconds: 60);

  // Curves.
  static const Curve standard = Curves.easeOutCubic;
  static const Curve overshoot = Curves.easeOutBack; // gentle pop
  static const Curve spring = Curves.elasticOut; // dials, taps, celebration

  /// Whether motion should play. False when the OS "remove animations"
  /// accessibility setting is on.
  static bool on(BuildContext context) =>
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);
}

/// Entrance animation for a single widget: fade + slide-up + a small scale pop.
extension RevealX on Widget {
  Widget reveal(BuildContext context, {Duration? delay}) {
    if (!AppMotion.on(context)) return this;
    return animate(delay: delay)
        .fadeIn(duration: AppMotion.entrance, curve: AppMotion.standard)
        .slideY(begin: 0.12, end: 0, duration: AppMotion.entrance, curve: AppMotion.standard)
        .scaleXY(begin: 0.97, end: 1, duration: AppMotion.entrance, curve: AppMotion.overshoot);
  }
}

/// Staggered entrance for a list of widgets (use directly as `children:`).
extension RevealListX on List<Widget> {
  List<Widget> revealStagger(BuildContext context, {Duration? interval}) {
    if (!AppMotion.on(context)) return this;
    return animate(interval: interval ?? AppMotion.stagger)
        .fadeIn(duration: AppMotion.entrance, curve: AppMotion.standard)
        .slideY(begin: 0.14, end: 0, duration: AppMotion.entrance, curve: AppMotion.standard)
        .scaleXY(begin: 0.96, end: 1, duration: AppMotion.entrance, curve: AppMotion.overshoot);
  }
}

/// A go_router page that transitions with the Material shared-axis pattern.
CustomTransitionPage<T> sharedAxisPage<T>({
  required LocalKey key,
  required Widget child,
  SharedAxisTransitionType type = SharedAxisTransitionType.scaled,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: AppMotion.medium,
    reverseTransitionDuration: AppMotion.medium,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      transitionType: type,
      fillColor: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    ),
  );
}

/// A go_router page that cross-fades through the background (fade-through).
CustomTransitionPage<T> fadeThroughPage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: AppMotion.medium,
    reverseTransitionDuration: AppMotion.medium,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeThroughTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      fillColor: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    ),
  );
}
