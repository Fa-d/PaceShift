import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/design.dart';
import '../../core/motion.dart';

/// A one-shot celebratory flourish: a confetti burst plus an elastic check-pop,
/// rendered in the app [Overlay] so it floats above the current screen.
///
/// No-op when reduced motion is requested. Call on delightful moments such as
/// marking a run complete.
class Celebrate {
  Celebrate._();

  static void burst(BuildContext context) {
    if (!AppMotion.on(context)) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final controller =
        ConfettiController(duration: const Duration(milliseconds: 900));
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CelebrationOverlay(controller: controller),
    );
    overlay.insert(entry);
    controller.play();

    Future.delayed(const Duration(milliseconds: 2600), () {
      entry.remove();
      controller.dispose();
    });
  }
}

class _CelebrationOverlay extends StatelessWidget {
  const _CelebrationOverlay({required this.controller});

  final ConfettiController controller;

  /// Confetti in the app's own accent language rather than five loose hexes.
  static List<Color> _colors(ColorScheme scheme) => [
        scheme.primary,
        scheme.success,
        scheme.info,
        scheme.warning,
        scheme.accentCool,
      ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: controller,
              blastDirection: math.pi / 2, // downward
              emissionFrequency: 0.05,
              numberOfParticles: 22,
              minBlastForce: 8,
              maxBlastForce: 24,
              gravity: 0.3,
              shouldLoop: false,
              colors: _colors(scheme),
            ),
          ),
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.4),
                    blurRadius: Space.xl,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(Icons.check_rounded,
                  color: scheme.onPrimary, size: 56),
            )
                .animate()
                .scaleXY(
                    begin: 0.2,
                    end: 1,
                    duration: 520.ms,
                    curve: Curves.elasticOut)
                .fadeIn(duration: 180.ms)
                .then(delay: 720.ms)
                .fadeOut(duration: 380.ms)
                .scaleXY(end: 0.9, duration: 380.ms),
          ),
        ],
      ),
    );
  }
}
