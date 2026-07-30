import 'package:flutter/material.dart';

import '../../core/design.dart';
import '../../core/formatting.dart';
import '../../core/theme.dart';
import '../../domain/models/enums.dart';
import 'count_up_text.dart';

/// The app's shared visual vocabulary.
///
/// ## Surface hierarchy
///
/// Three tiers, and the tier *is* the hierarchy. Every card in the app used to
/// be the same `Card` — same fill, same elevation, same radius — so the primary
/// action and a dismissed-permission nag carried identical visual weight and
/// the screen read as an undifferentiated pile.
///
/// * [HeroSurface] — the one thing that matters on this screen. **At most one.**
/// * [QuietSurface] — supporting context. Hairline, no fill.
/// * inline rows — no container at all; see `SettingsSection`.

/// The single most important surface on a screen: tinted, filled, loud.
///
/// Use for today's run, and nothing else on that screen.
class HeroSurface extends StatelessWidget {
  const HeroSurface({
    super.key,
    required this.child,
    this.tint,
    this.onTap,
  });

  final Widget child;

  /// Accent the surface is tinted with. Defaults to the brand primary.
  final Color? tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = tint ?? scheme.primary;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: AppRadius.lgAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.tint, color.withValues(alpha: 0.02)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Supporting context: a hairline outline, no fill, quieter radius.
///
/// Deliberately recedes next to a [HeroSurface].
class QuietSurface extends StatelessWidget {
  const QuietSurface({
    super.key,
    required this.child,
    this.onTap,
    this.accent,
    this.padding = const EdgeInsets.all(Space.lg),
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Tints the border and adds a faint wash — for surfaces that need to be
  /// noticed without being promoted to a hero (e.g. the attention queue).
  final Color? accent;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = accent ?? scheme.outlineVariant;
    return Material(
      color: accent?.withValues(alpha: 0.05) ?? Colors.transparent,
      clipBehavior: Clip.antiAlias,
      // `shape` only — Material asserts that `shape` and `borderRadius` are
      // never both supplied, and the outline is the whole point of this tier.
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: BorderSide(
            color: accent != null ? border.withValues(alpha: 0.35) : border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// A circular icon chip tinted with a run type's colour.
class RunTypeBadge extends StatelessWidget {
  const RunTypeBadge({super.key, required this.type, this.size = 44});

  final RunType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = RunPalette.of(type, scheme);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.tint, shape: BoxShape.circle),
      child: Icon(RunPalette.icon(type), color: color, size: size * 0.5),
    );
  }
}

/// A round icon chip in an arbitrary accent — the non-run-type sibling of
/// [RunTypeBadge].
class IconChip extends StatelessWidget {
  const IconChip({
    super.key,
    required this.icon,
    this.color,
    this.size = 40,
  });

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tint.tint, shape: BoxShape.circle),
      child: Icon(icon, color: tint, size: size * 0.5),
    );
  }
}

/// A small status chip ("Completed", "Moved", …).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final RunStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = statusColor(status, theme.colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Space.md, vertical: Space.xs),
      decoration: BoxDecoration(
        color: color.tint,
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        runStatusLabel(status),
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

/// A labelled metric, e.g. a big number above a caption.
class MetricBlock extends StatelessWidget {
  const MetricBlock({
    super.key,
    this.value,
    required this.label,
    this.color,
    this.countTo,
    this.countFormat,
  }) : assert(value != null || (countTo != null && countFormat != null),
            'MetricBlock needs either a value or a countTo/countFormat pair');

  /// The rendered value, for metrics that aren't a single animatable number
  /// (pace, run/walk ratio). Ignored when [countTo] and [countFormat] are set —
  /// pass one or the other, never both, or the two can silently disagree.
  final String? value;
  final String label;
  final Color? color;

  /// When set together with [countFormat], the value counts up from zero.
  final num? countTo;
  final String Function(num)? countFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.titleLarge?.copyWith(color: color);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (countTo != null && countFormat != null)
          CountUpText(value: countTo!, format: countFormat!, style: valueStyle)
        else
          Text(value!, style: valueStyle),
        const SizedBox(height: Space.xs),
        Text(
          label,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Friendly empty-state placeholder.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: Space.lg),
            Text(title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: Space.sm),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
            if (action != null) ...[
              const SizedBox(height: Space.xl),
              action!
            ],
          ],
        ),
      ),
    );
  }
}

/// The one way an error reaches a user: a plain-language message and a way out.
///
/// Pair with `friendlyError()` from `core/errors.dart` — never interpolate the
/// exception itself.
class SurfaceError extends StatelessWidget {
  const SurfaceError({
    super.key,
    required this.message,
    this.onRetry,
    this.compact = false,
  });

  final String message;
  final VoidCallback? onRetry;

  /// Renders inline (for a slot inside a screen) rather than centred and full
  /// height.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (compact) {
      return QuietSurface(
        accent: scheme.danger,
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: scheme.danger, size: 20),
            const SizedBox(width: Space.md),
            Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
            if (onRetry != null) ...[
              const SizedBox(width: Space.sm),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      );
    }

    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'That didn’t work',
      message: message,
      action: onRetry == null
          ? null
          : FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
    );
  }
}

/// Section heading used between surfaces.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.xs, Space.sm, Space.xs, Space.sm),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

/// Inline banner showing a run was moved from its original date.
class ShiftBanner extends StatelessWidget {
  const ShiftBanner({super.key, required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = statusColor(RunStatus.shifted, theme.colorScheme);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.swap_horiz_rounded, size: 16, color: color),
        const SizedBox(width: Space.xs),
        Text('Moved from ${formatDateLabel(from)}',
            style: theme.textTheme.labelSmall?.copyWith(color: color)),
      ],
    );
  }
}

/// Icon + title + description row used by onboarding, the connect screen and
/// the paywall to sell a feature.
///
/// Previously three near-identical private copies (`_FeatureRow`, `_Benefit`,
/// and the paywall's inline row) that had drifted to three different icon
/// tints and a copy-pasted 7px optical nudge.
class FeatureRow extends StatelessWidget {
  const FeatureRow({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? description;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconChip(icon: icon, color: color, size: 36),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                if (description != null) ...[
                  const SizedBox(height: Space.xs),
                  Text(description!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
