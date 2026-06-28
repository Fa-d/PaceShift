import 'package:flutter/material.dart';

import '../../core/motion.dart';

/// Text that animates a number from its previous value up to [value], formatting
/// each interpolated frame with [format]. Renders the final value instantly when
/// reduced motion is requested.
///
/// Pair with the formatters in `core/formatting.dart`, e.g.
/// `CountUpText(value: km, format: (n) => formatKm(n.toDouble()))`.
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.duration,
    this.curve = AppMotion.standard,
    this.textAlign,
  });

  final num value;
  final String Function(num) format;
  final TextStyle? style;
  final Duration? duration;
  final Curve curve;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    if (!AppMotion.on(context)) {
      return Text(format(value), style: style, textAlign: textAlign);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration ?? const Duration(milliseconds: 700),
      curve: curve,
      builder: (context, v, _) =>
          Text(format(v), style: style, textAlign: textAlign),
    );
  }
}
