import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'genui_surface_view.dart';

/// A dedicated full-screen surface for free-form coaching questions answered
/// with generative UI (Phase 12). Reachable via the `/coach` route.
class AskCoachScreen extends ConsumerWidget {
  const AskCoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ask your coach')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: GenUiSurfaceView(
            emptyHint:
                'Ask anything — “How’s my week?”, “Am I ready for my long run?”, '
                '“What changed after I missed Tuesday?”',
          ),
        ),
      ),
    );
  }
}
