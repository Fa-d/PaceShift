import 'package:flutter/material.dart';

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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              title!.toUpperCase(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
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
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (leading != null) ...[
              Icon(leading, color: titleColor ?? scheme.onSurfaceVariant, size: 22),
              const SizedBox(width: 16),
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
                    const SizedBox(height: 2),
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
              const SizedBox(width: 12),
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
