import 'package:flutter/material.dart';

import '../domain/models/enums.dart';

/// PaceShift visual identity.
///
/// Athletic, momentum-forward: a warm **ember** accent against cool slate
/// neutrals, with a consistent run-type colour language used across cards,
/// the calendar, and charts.
class AppTheme {
  AppTheme._();

  static const Color ember = Color(0xFFFF5A2C); // energetic accent
  static const Color slate = Color(0xFF2B3A4A); // cool neutral

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: ember,
      brightness: brightness,
      secondary: slate,
      // Keep the ember vivid for CTAs rather than the muted M3-derived tone.
      primary: brightness == Brightness.light ? ember : const Color(0xFFFF7E54),
      onPrimary: Colors.white,
    );
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
    );
    return base.copyWith(
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      textTheme: base.textTheme.copyWith(
        displaySmall: base.textTheme.displaySmall
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1),
        headlineMedium: base.textTheme.headlineMedium
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleLarge:
            base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Run-type colour language. Kept stable so the calendar, cards, and charts
/// all read the same way.
class RunPalette {
  RunPalette._();

  static Color of(RunType type, ColorScheme scheme) {
    switch (type) {
      case RunType.long:
        return AppTheme.ember;
      case RunType.steady:
        return const Color(0xFF3A7BD5); // blue
      case RunType.easy:
        return const Color(0xFF2BB673); // green
      case RunType.cross:
        return const Color(0xFF8A63D2); // purple
      case RunType.strength:
        return const Color(0xFFB5651D); // bronze
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
      return const Color(0xFF2BB673);
    case RunStatus.missed:
      return scheme.error;
    case RunStatus.shifted:
      return const Color(0xFFE0A800);
    case RunStatus.dropped:
      return scheme.outlineVariant;
    case RunStatus.pending:
      return scheme.primary;
  }
}
