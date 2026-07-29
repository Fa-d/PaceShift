import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
import '../providers/entitlement_providers.dart';
import '../providers/subscription_providers.dart';
import '../widgets/common.dart';
import 'genui_surface_view.dart';

/// The one place for free-form coaching questions, answered with generative UI.
///
/// There used to be a `CoachChatSheet` rendering the identical surface in a
/// bottom sheet, with an "open full screen" button that popped it and pushed
/// here — two doors to one room, and only the sheet was Pro-gated while this
/// route was wide open. The sheet is gone; this screen owns the gate, so a
/// deep link can't walk around it either.
class AskCoachScreen extends ConsumerWidget {
  const AskCoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(proStatusProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ask your coach')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              Space.lg, Space.sm, Space.lg, Space.lg),
          child: isPro
              ? const GenUiSurfaceView(
                  emptyHint:
                      'Ask anything — “How’s my week?”, “Am I ready for my '
                      'long run?”, “What changed after I missed Tuesday?”',
                )
              : EmptyState(
                  icon: Icons.psychology_rounded,
                  title: 'Coaching is part of Pro',
                  message: 'Ask anything about your plan and get every change '
                      'explained in plain language.',
                  action: FilledButton(
                    onPressed: () => showPaywall(context),
                    child: const Text('See what’s included'),
                  ),
                ),
        ),
      ),
    );
  }
}
