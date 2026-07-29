import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
import '../../core/motion.dart';
import '../providers/auth_providers.dart';
import '../auth/sign_in_screen.dart';
import '../widgets/common.dart';

/// One Pro benefit row.
class _Benefit {
  const _Benefit(this.icon, this.title, this.subtitle);
  final IconData icon;
  final String title;
  final String subtitle;
}

/// What Pro actually unlocks.
///
/// This list used to advertise five things and gate one. The adaptive engine,
/// watch sync, stats, predictions and pace-based workouts all run for free —
/// they are the core loop, and gating the loop is what made the product feel
/// like a bait-and-switch. Only these two are behind the wall, so only these
/// two are sold.
const _benefits = <_Benefit>[
  _Benefit(Icons.psychology_rounded, 'AI coaching',
      'Ask your coach anything, and get every plan change explained'),
  _Benefit(Icons.cloud_done_rounded, 'Cloud backup & sync',
      'Your plan and history, safe and on every device you own'),
];

/// What everyone gets, stated plainly so the wall never reads as a hostage
/// note. Naming the free features is also the honest answer to "what am I
/// actually paying for?".
const _included = <_Benefit>[
  _Benefit(Icons.auto_fix_high_rounded, 'The adaptive engine',
      'Miss a run and your week reshuffles safely — always free'),
  _Benefit(Icons.watch_rounded, 'Automatic run capture',
      'Runs import themselves from Health Connect / HealthKit — always free'),
  _Benefit(Icons.insights_rounded, 'Stats, readiness & predictions',
      'Charts, streaks and your predicted finish — always free'),
];

/// The Pro upsell. The actual purchase is delegated to [onSubscribe] so this
/// widget stays decoupled from the billing SDK.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({
    super.key,
    required this.onSubscribe,
    required this.onRestore,
    this.busy = false,
    this.priceLabel,
  });

  final Future<void> Function(BuildContext, WidgetRef) onSubscribe;
  final Future<void> Function(BuildContext, WidgetRef) onRestore;
  final bool busy;
  final String? priceLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final signedIn = ref.watch(isSignedInProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('PaceShift Pro')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    Space.screenH, Space.lg, Space.screenH, Space.sm),
                children: [
                  const IconChip(icon: Icons.bolt_rounded, size: 64),
                  const SizedBox(height: Space.lg),
                  Text('Coaching and backup',
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: Space.xs),
                  Text(
                    'Your training already adapts for free. Pro adds a coach '
                    'that explains it, and a backup so you never lose it.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: Space.xl),
                  ..._benefits.map((b) => FeatureRow(
                        icon: b.icon,
                        title: b.title,
                        description: b.subtitle,
                      )),
                  const SizedBox(height: Space.xl),
                  const SectionHeader('Free, and staying free'),
                  ..._included.map((b) => FeatureRow(
                        icon: b.icon,
                        title: b.title,
                        description: b.subtitle,
                        color: scheme.onSurfaceVariant,
                      )),
                ].revealStagger(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Space.screenH, 0, Space.screenH, Space.sm),
              child: Column(
                children: [
                  if (!signedIn)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.sm),
                      child: Text(
                        'Sign in first so your subscription follows your account.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  FilledButton(
                    onPressed: busy ? null : () => _start(context, ref, signedIn),
                    child: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        // The label must describe what the tap does. When
                        // signed out this button opens sign-in, so promising a
                        // trial it can't start was a dead end.
                        : Text(!signedIn
                            ? 'Sign in to continue'
                            : priceLabel == null
                                ? 'Start 7-day free trial'
                                : 'Start free trial · $priceLabel'),
                  ),
                  TextButton(
                    onPressed: busy ? null : () => onRestore(context, ref),
                    child: const Text('Restore purchases'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Signing in is a step *towards* subscribing, not a substitute for it — so
  /// a successful sign-in continues straight into the purchase rather than
  /// silently returning the user to the paywall.
  Future<void> _start(
      BuildContext context, WidgetRef ref, bool signedIn) async {
    if (!signedIn) {
      await showSignIn(context);
      if (!context.mounted || !ref.read(isSignedInProvider)) return;
    }
    if (context.mounted) await onSubscribe(context, ref);
  }
}
