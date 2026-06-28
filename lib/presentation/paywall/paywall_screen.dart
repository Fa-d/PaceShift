import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import '../providers/auth_providers.dart';
import '../auth/sign_in_screen.dart';

/// One Pro benefit row.
class _Benefit {
  const _Benefit(this.icon, this.title, this.subtitle);
  final IconData icon;
  final String title;
  final String subtitle;
}

const _benefits = <_Benefit>[
  _Benefit(Icons.auto_fix_high_rounded, 'Adaptive engine',
      'Miss a run and PaceShift safely reshuffles your week'),
  _Benefit(Icons.watch_rounded, 'Watch sync',
      'Auto-import runs from Health Connect / HealthKit'),
  _Benefit(Icons.insights_rounded, 'Full stats & predictions',
      'Readiness dial, charts, and your predicted finish time'),
  _Benefit(Icons.speed_rounded, 'Pace-based workouts',
      'Goal-time targeting with intervals & tempo sessions'),
  _Benefit(Icons.psychology_rounded, 'AI coaching',
      'Plain-language explanations of every plan change'),
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
    final signedIn = ref.watch(isSignedInProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('PaceShift Pro')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.ember.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.bolt_rounded,
                        color: AppTheme.ember, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text('Train smarter, adapt safely',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    'Unlock the adaptive engine and everything that makes your '
                    'plan respond to real life.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  ..._benefits.map((b) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(b.icon, color: AppTheme.ember),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(b.title,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w600)),
                                  Text(b.subtitle,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                          color:
                                              theme.colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                ].revealStagger(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                children: [
                  if (!signedIn)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Sign in first so your subscription follows your account.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () async {
                            if (!signedIn) {
                              await showSignIn(context);
                              return;
                            }
                            if (context.mounted) await onSubscribe(context, ref);
                          },
                    child: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(priceLabel == null
                            ? 'Start 7-day free trial'
                            : 'Start free trial · $priceLabel'),
                  ),
                  TextButton(
                    onPressed:
                        busy ? null : () => onRestore(context, ref),
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
}
