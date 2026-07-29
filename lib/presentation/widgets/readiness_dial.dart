import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../domain/readiness/readiness_scorer.dart';

/// A circular 0–100 readiness dial with the score and plain-language band.
///
/// On first appearance the arc sweeps in (with a gentle overshoot) and the
/// score counts up from zero. Renders fully filled instantly under reduced
/// motion.
class ReadinessDial extends StatelessWidget {
  const ReadinessDial({super.key, required this.readiness, this.size = 180});

  final ReadinessScore readiness;
  final double size;

  Widget _dial(ThemeData theme, Color color, double progress, int score) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DialPainter(
          progress: progress,
          color: color,
          track: theme.colorScheme.surfaceContainerHighest,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$score',
                  style: theme.textTheme.displaySmall?.copyWith(color: color)),
              Text(readiness.label,
                  style: theme.textTheme.titleSmall?.copyWith(color: color)),
              const SizedBox(height: Space.xs),
              Text('readiness',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = readinessColor(readiness.band, theme.colorScheme);
    final target = readiness.score / 100;
    if (!AppMotion.on(context)) {
      return _dial(theme, color, target, readiness.score);
    }
    // Animate a single 0→1 driver: the arc overshoots, the number stays linear.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppMotion.fill,
      curve: Curves.linear,
      builder: (context, t, _) => _dial(
        theme,
        color,
        target * Curves.easeOutBack.transform(t.clamp(0, 1)),
        (readiness.score * t).round(),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  // A 270° arc (gauge style) starting from the bottom-left.
  static const _start = math.pi * 0.75;
  static const _sweep = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = track;
    final valuePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(rect, _start, _sweep, false, trackPaint);
    canvas.drawArc(rect, _start, _sweep * progress.clamp(0, 1), false, valuePaint);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.progress != progress || old.color != color;
}
