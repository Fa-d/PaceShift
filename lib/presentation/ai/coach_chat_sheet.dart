import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../genui/genui_surface_view.dart';
import '../widgets/pro_gate.dart';

/// AI coaching chat that renders **generative UI** (Phase 12, Pro-gated).
///
/// Questions are answered with native, AI-composed surfaces (metrics, run cards,
/// banners, actions) via [GenUiSurfaceView] — the backend GLM 5.2 proxy returns
/// a structured UI spec the genui catalog renders. Replaces the old plain-text
/// chat bubbles.
class CoachChatSheet extends ConsumerWidget {
  const CoachChatSheet({super.key});

  static Future<void> show(BuildContext context, WidgetRef ref) async {
    if (!await ensurePro(context, ref)) return;
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const CoachChatSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_rounded, color: AppTheme.ember),
              const SizedBox(width: 8),
              Text('Ask your coach', style: theme.textTheme.titleLarge),
              const Spacer(),
              IconButton(
                tooltip: 'Open full screen',
                icon: const Icon(Icons.open_in_full_rounded),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/coach');
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6),
            child: const GenUiSurfaceView(),
          ),
        ],
      ),
    );
  }
}
