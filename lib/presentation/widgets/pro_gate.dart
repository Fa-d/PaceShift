import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// A small "PRO" pill for labelling gated features in the UI.
class ProBadge extends StatelessWidget {
  const ProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'PRO',
        style: TextStyle(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
