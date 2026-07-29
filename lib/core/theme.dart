import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../domain/models/enums.dart';
import 'design.dart';

/// PaceShift visual identity.
///
/// Athletic, momentum-forward: a warm **ember** accent against cool slate
/// neutrals, with a consistent run-type colour language used across cards,
/// the calendar, and charts.
///
/// The brand seeds are deliberately **private**. They are light-mode values —
/// using them directly meant a widget rendered the light orange while its
/// neighbour rendered `scheme.primary`'s dark-mode orange, so a single screen
/// showed two different brand colours in dark mode. Always reach for
/// `Theme.of(context).colorScheme.primary`; the seeds only feed the scheme.
class AppTheme {
  AppTheme._();

  static const Color _emberSeed = Color(0xFFFF5A2C); // energetic accent
  static const Color _slateSeed = Color(0xFF2B3A4A); // cool neutral

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _emberSeed,
      brightness: brightness,
      secondary: _slateSeed,
      // Keep the ember vivid for CTAs rather than the muted M3-derived tone.
      primary:
          brightness == Brightness.light ? _emberSeed : const Color(0xFFFF7E54),
      onPrimary: Colors.white,
    );
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
    );
    return base.copyWith(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SharedAxisPageTransitionsBuilder(
              transitionType: SharedAxisTransitionType.horizontal),
          TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(
              transitionType: SharedAxisTransitionType.horizontal),
        },
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: Space.lg, vertical: Space.md + 2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      textTheme: _textTheme(base.textTheme),
    );
  }

  /// A committed type scale.
  ///
  /// Every role carries its own weight so call sites never patch
  /// `fontWeight` — 19 of them used to. One role per level, applied
  /// consistently:
  ///
  /// * `displaySmall`  — hero numbers (finish time, countdown)
  /// * `headlineMedium`— screen title
  /// * `titleLarge`    — hero surface heading
  /// * `titleMedium`   — quiet surface heading
  /// * `bodyMedium`    — body copy
  /// * `labelSmall`    — metric captions, overlines
  ///
  /// Display and title roles use **tabular figures** so the numbers that
  /// animate through `CountUpText` don't jitter as digits change width.
  static TextTheme _textTheme(TextTheme base) {
    const tabular = <FontFeature>[FontFeature.tabularFigures()];
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
          fontFeatures: tabular),
      displayMedium: base.displayMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          fontFeatures: tabular),
      displaySmall: base.displaySmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
          fontFeatures: tabular),
      headlineLarge: base.headlineLarge
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.6),
      headlineMedium: base.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineSmall: base.headlineSmall
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4),
      titleLarge: base.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          fontFeatures: tabular),
      titleMedium: base.titleMedium
          ?.copyWith(fontWeight: FontWeight.w600, fontFeatures: tabular),
      titleSmall: base.titleSmall
          ?.copyWith(fontWeight: FontWeight.w600, fontFeatures: tabular),
      bodyLarge: base.bodyLarge?.copyWith(fontWeight: FontWeight.w400),
      bodyMedium: base.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
      bodySmall: base.bodySmall?.copyWith(fontWeight: FontWeight.w400),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      labelSmall: base.labelSmall
          ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.4),
    );
  }
}

/// Run-type colour language. Kept stable so the calendar, cards, and charts
/// all read the same way.
///
/// Every colour resolves through the semantic layer in `design.dart`, so a
/// completed easy run and a "success" chip are the *same* green rather than
/// two hexes that happen to look alike.
class RunPalette {
  RunPalette._();

  static Color of(RunType type, ColorScheme scheme) {
    switch (type) {
      case RunType.long:
        return scheme.primary;
      case RunType.steady:
        return scheme.info;
      case RunType.easy:
        return scheme.success;
      case RunType.cross:
        return scheme.accentCool;
      case RunType.strength:
        return scheme.accentWarm;
      case RunType.rest:
        return scheme.outline;
    }
  }

  static IconData icon(RunType type) {
    switch (type) {
      case RunType.long:
        return Icons.terrain_rounded;
      case RunType.steady:
        return Icons.speed_rounded;
      case RunType.easy:
        return Icons.directions_walk_rounded;
      case RunType.cross:
        return Icons.pedal_bike_rounded;
      case RunType.strength:
        return Icons.fitness_center_rounded;
      case RunType.rest:
        return Icons.bedtime_rounded;
    }
  }
}

/// Colour for a run lifecycle status (used by calendar dots and badges).
Color statusColor(RunStatus status, ColorScheme scheme) {
  switch (status) {
    case RunStatus.completed:
      return scheme.success;
    case RunStatus.missed:
      return scheme.danger;
    case RunStatus.shifted:
      return scheme.warning;
    case RunStatus.dropped:
      return scheme.outlineVariant;
    case RunStatus.pending:
      return scheme.primary;
  }
}
