import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genui/genui.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../domain/models/enums.dart';
import '../providers/auth_providers.dart';
import '../providers/providers.dart';
import '../shift/shift_summary.dart';
import 'paceshift_catalog.dart';

/// Renders AI-composed generative UI for PaceShift.
///
/// Owns a genui [SurfaceController] + [A2uiTransportAdapter] + [Conversation],
/// fetches a UI spec from the backend (`POST /ai/ui`, GLM 5.2), maps it to A2UI
/// messages ([specToMessages]) and renders each surface natively via the
/// PaceShift catalog. Interactions ([GenUiAction]) are handled client-side
/// (deep-link, engine action, or re-compose — the feedback loop).
///
/// Reused by the Coach chat, the Shift "Coach's take" flow, the Today dashboard,
/// and the "Ask your coach" screen.
class GenUiSurfaceView extends ConsumerStatefulWidget {
  const GenUiSurfaceView({
    super.key,
    this.changes = const [],
    this.initialQuestion,
    this.composeOnStart = false,
    this.showInput = true,
    this.emptyHint =
        'Ask about your plan, pacing, or how to handle a missed run.',
  });

  /// Engine changelog lines used to ground the composition (e.g. a reshuffle).
  final List<String> changes;

  /// A question to compose an answer for as soon as the view mounts.
  final String? initialQuestion;

  /// Compose an initial surface on mount even without a question (e.g. a
  /// dashboard section grounded purely in [changes] + the plan summary).
  final bool composeOnStart;

  /// Whether to show the free-form question input row.
  final bool showInput;

  /// Hint shown before any surface exists.
  final String emptyHint;

  @override
  ConsumerState<GenUiSurfaceView> createState() => _GenUiSurfaceViewState();
}

class _GenUiSurfaceViewState extends ConsumerState<GenUiSurfaceView> {
  late final SurfaceController _controller;
  late final A2uiTransportAdapter _transport;
  late final Conversation _conversation;
  StreamSubscription<ConversationEvent>? _eventsSub;

  final _input = TextEditingController();
  final _surfaceIds = <String>[];
  final _contexts = <String, SurfaceContext>{};
  bool _busy = false;
  int _turn = 0;

  @override
  void initState() {
    super.initState();
    _controller =
        SurfaceController(catalogs: [buildPaceShiftCatalog(onAction: _onAction)]);
    // We drive surfaces directly via addMessage and handle interactions through
    // _onAction, so onSend is only a safety sink for any internal submissions.
    _transport = A2uiTransportAdapter(onSend: (_) async {});
    _conversation =
        Conversation(controller: _controller, transport: _transport);
    _eventsSub = _conversation.events.listen(_onConversationEvent);

    if (widget.initialQuestion != null || widget.composeOnStart) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _compose(widget.initialQuestion),
      );
    }
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _conversation.dispose();
    _transport.dispose();
    _controller.dispose();
    _input.dispose();
    super.dispose();
  }

  void _onConversationEvent(ConversationEvent event) {
    if (!mounted) return;
    if (event is ConversationSurfaceAdded) {
      setState(() => _surfaceIds.add(event.surfaceId));
    } else if (event is ConversationSurfaceRemoved) {
      setState(() {
        _surfaceIds.remove(event.surfaceId);
        _contexts.remove(event.surfaceId);
      });
    }
  }

  /// Fetches a fresh surface. [changes] overrides the grounding changelog (used
  /// after an engine action re-grounds on a new RescheduleOutcome).
  Future<void> _compose(String? question, {List<String>? changes}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final spec = await ref.read(genUiRepositoryProvider).compose(
          planSummary: ref.read(planSummaryProvider),
          changes: changes ?? widget.changes,
          question: question,
        );
    if (!mounted) return;
    final surfaceId = 's${_turn++}';
    for (final message in specToMessages(spec, surfaceId)) {
      _transport.addMessage(message);
    }
    setState(() => _busy = false);
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty || _busy) return;
    _input.clear();
    _compose(text);
  }

  /// Executes a generated interaction against the real app — the engine stays
  /// pure; the *client* performs the action, then re-composes so the next AI
  /// turn reflects the new state (the feedback loop).
  Future<void> _onAction(GenUiAction action) async {
    if (action.confirm) {
      final ok = await _confirm(action.label ?? 'this action');
      if (ok != true) return;
    }
    switch (action.action) {
      case 'open_run':
        if (action.runId != null && mounted) {
          context.push('/run/${action.runId}');
        }
      case 'mark_done':
        if (action.runId == null) return;
        await ref
            .read(runRepositoryProvider)
            .updateRunStatus(action.runId!, RunStatus.completed);
        _toast('Marked done — nice work.');
        await _compose('I just marked that run as done.');
      case 'could_not_run':
        if (action.runId == null) return;
        final outcome = await ref
            .read(schedulerRepositoryProvider)
            .reportCouldNotRun(action.runId!, today: ref.read(todayProvider));
        if (outcome == null) {
          _toast('Couldn’t adjust the plan right now.');
          return;
        }
        if (outcome.needsDecision) {
          if (mounted) {
            await DegradeDecisionSheet.show(context, outcome.decisions);
          }
          return;
        }
        _toast('Plan adjusted around that run.');
        // Re-ground the next surface on the fresh reshuffle changelog.
        await _compose(
          'I couldn’t run that one — what changed and why is it still safe?',
          changes: changeLines(outcome),
        );
      default:
        await _compose(action.label);
    }
  }

  Future<bool?> _confirm(String what) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Confirm $what?'),
          content: const Text('This changes your training plan.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirm')),
          ],
        ),
      );

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: _surfaceIds.isEmpty && !_busy
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    widget.emptyHint,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _surfaceIds.length,
                  itemBuilder: (_, i) {
                    final id = _surfaceIds[i];
                    final ctx = _contexts[id] ??= _controller.contextFor(id);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Surface(surfaceContext: ctx),
                    );
                  },
                ),
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          ),
        if (widget.showInput) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration:
                      const InputDecoration(hintText: 'Type a question…'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _busy ? null : _send,
                icon: const Icon(Icons.send_rounded),
                color: AppTheme.ember,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
