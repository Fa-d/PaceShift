import 'package:flutter/material.dart';

/// The app's design tokens — the spatial and semantic-colour counterpart to
/// [AppMotion] in `motion.dart`.
///
/// Everything in `lib/presentation/` sizes, spaces and colours itself from
/// here. The rule is simple: **no raw numbers and no raw hex at a call site.**
/// Before this file existed the presentation layer carried ~270 one-off
/// literals — 137 `SizedBox` gaps across 21 distinct values, four different
/// card paddings on a single screen, and three subtly different greens — which
/// is what made the app read as unfinished rather than designed.

/// Spacing, on a strict 4pt grid. Six values, no in-betweens.
///
/// If a gap seems to need `10` or `18`, it needs [sm] or [lg]; the eye reads
/// rhythm, not precision, and an inconsistent rhythm is exactly what "all over
/// the place" looks like.
class Space {
  Space._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Standard horizontal inset for a scrollable screen body.
  static const double screenH = 20;

  /// Standard bottom inset so content clears the navigation bar.
  static const double screenBottom = 32;

  /// The one padding a screen-level scroll view should use.
  static const EdgeInsets screenPadding =
      EdgeInsets.fromLTRB(screenH, lg, screenH, screenBottom);
}

/// Corner radii. Tiers, not a continuum.
class AppRadius {
  AppRadius._();

  /// Chips, dots, small tags.
  static const double sm = 8;

  /// Inputs, quiet surfaces, secondary containers.
  static const double md = 14;

  /// Hero surfaces and cards.
  static const double lg = 20;

  /// Fully rounded (status chips, pills).
  static const double pill = 999;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get pillAll => BorderRadius.circular(pill);
}

/// Opacity tiers. Five hand-typed values between 0.10 and 0.16 are
/// indistinguishable to the eye and distinguishable only to a diff — so there
/// are three.
class Alpha {
  Alpha._();

  /// Barely-there borders and dividers.
  static const double hairline = 0.08;

  /// Icon-chip and badge backgrounds, gradient tails.
  static const double tint = 0.14;

  /// De-emphasised foreground text over a tinted surface.
  static const double muted = 0.60;
}

/// Semantic colours, resolved per brightness.
///
/// These exist because `ColorScheme` has no "success" or "warning" — so every
/// call site that needed one invented a hex, and the app ended up shipping
/// three greens (`2BB673`, `2E7D32`, and an M3-derived tertiary) plus three
/// ambers. Reach for these instead; they are correct in both themes.
extension AppColors on ColorScheme {
  bool get _dark => brightness == Brightness.dark;

  /// Completed runs, on-track readiness, positive deltas.
  Color get success =>
      _dark ? const Color(0xFF4BD292) : const Color(0xFF1E9E63);

  /// Moved/shifted runs, "slightly behind" readiness, soft warnings.
  Color get warning =>
      _dark ? const Color(0xFFE8B93A) : const Color(0xFFB26A00);

  /// Missed runs, destructive actions, "at risk".
  Color get danger => error;

  /// Steady runs, neutral informational accents.
  Color get info => _dark ? const Color(0xFF7BA9E8) : const Color(0xFF3A7BD5);

  /// Cross-training.
  Color get accentCool =>
      _dark ? const Color(0xFFB794E8) : const Color(0xFF8A63D2);

  /// Strength work.
  Color get accentWarm =>
      _dark ? const Color(0xFFD08B4F) : const Color(0xFFB5651D);
}

/// Terse, consistent tinting so nobody hand-types an alpha again.
extension ColorTintX on Color {
  /// A filled background tint of this colour (badges, chips, gradients).
  Color get tint => withValues(alpha: Alpha.tint);

  /// A hairline border of this colour.
  Color get hairline => withValues(alpha: Alpha.hairline);

  /// This colour de-emphasised as foreground.
  Color get muted => withValues(alpha: Alpha.muted);
}
