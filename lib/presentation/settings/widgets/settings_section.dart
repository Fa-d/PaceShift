import 'package:flutter/material.dart';

import '../../../core/design.dart';

/// Flat grouped-list primitives for Settings (hub + sub-pages).
///
/// The look: a small-caps label above a single rounded container whose rows are
/// divided by hairlines — an iOS-style inset grouped list, kept minimal. Used by
/// the Settings hub and every Settings sub-page so the styling stays consistent.

/// An uppercase section label above one rounded group of [SettingsTile]s.
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, this.title, required this.children});

  /// Small-caps heading. Omit for a label-less group.
  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Space.lg, 0, Space.lg, Space.sm),
            child: Text(
              title!.toUpperCase(),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: AppRadius.lgAll,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: Space.lg,
                    endIndent: Space.lg,
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One row inside a [SettingsSection]. Rounds its corners only when it's the sole
/// child so a single-row group still reads as one rounded card.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  final IconData? leading;
  final String title;
  final String? subtitle;

  /// A value `Text`, a control (e.g. `SegmentedButton`), or null for a chevron
  /// when [onTap] is set.
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Tints the leading icon + title (e.g. error red for destructive actions).
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final effectiveTrailing = trailing ??
        (onTap != null
            ? Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant)
            : null);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Space.lg, vertical: Space.md),
        child: Row(
          children: [
            if (leading != null) ...[
              Icon(leading, color: titleColor ?? scheme.onSurfaceVariant, size: 22),
              const SizedBox(width: Space.lg),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(color: titleColor),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: Space.xs),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            if (effectiveTrailing != null) ...[
              const SizedBox(width: Space.md),
              DefaultTextStyle.merge(
                style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant) ??
                    const TextStyle(),
                child: effectiveTrailing,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
