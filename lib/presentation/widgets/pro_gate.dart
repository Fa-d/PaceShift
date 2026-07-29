import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
import '../providers/entitlement_providers.dart';
import '../providers/subscription_providers.dart';

/// Returns true if the user has Pro; otherwise opens the paywall and returns
/// false. Use to gate Pro-only actions (the adaptive engine, sync, AI, …).
///
/// ```dart
/// if (!await ensurePro(context, ref)) return;
/// ```
Future<bool> ensurePro(BuildContext context, WidgetRef ref) async {
  if (ref.read(proStatusProvider)) return true;
  await showPaywall(context);
  return ref.read(proStatusProvider);
}

/// A small "PRO" pill for labelling gated features *before* the user taps them.
///
/// Pro used to be discoverable only by hitting a wall — this widget existed but
/// was never rendered anywhere. It is now the standing marker on gated
/// surfaces so a paywall is never a surprise.
class ProBadge extends StatelessWidget {
  const ProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        'PRO',
        style: theme.textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.onPrimary),
      ),
    );
  }
}
