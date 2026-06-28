import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
import '../../domain/models/planned_run.dart';
import '../providers/providers.dart';
import 'celebration.dart';

/// Bottom sheet to log a run — either completing a [plannedRun] or recording an
/// extra/unplanned run. The manual fallback that's always available (spec §6).
class ManualLogSheet extends ConsumerStatefulWidget {
  const ManualLogSheet({super.key, this.plannedRun});

  final PlannedRun? plannedRun;

  static Future<void> show(BuildContext context, {PlannedRun? plannedRun}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ManualLogSheet(plannedRun: plannedRun),
    );
  }

  @override
  ConsumerState<ManualLogSheet> createState() => _ManualLogSheetState();
}

class _ManualLogSheetState extends ConsumerState<ManualLogSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _distance;
  late final TextEditingController _minutes;
  final _avgHr = TextEditingController();
  final _maxHr = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _distance = TextEditingController(
      text: widget.plannedRun?.targetDistanceKm?.toString() ?? '',
    );
    _minutes = TextEditingController(
      text: widget.plannedRun?.targetDurationMin?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _distance.dispose();
    _minutes.dispose();
    _avgHr.dispose();
    _maxHr.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(runRepositoryProvider);
    final dist = double.parse(_distance.text.trim());
    final durSec = ((double.tryParse(_minutes.text.trim()) ?? 0) * 60).round();
    final avgHr = int.tryParse(_avgHr.text.trim());
    final maxHr = int.tryParse(_maxHr.text.trim());
    final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();

    try {
      final planned = widget.plannedRun;
      if (planned != null) {
        await repo.logManualCompletion(
          planned,
          distanceKm: dist,
          durationSec: durSec,
          avgHr: avgHr,
          maxHr: maxHr,
          notes: notes,
        );
      } else {
        await repo.logExtraRun(
          date: ref.read(todayProvider),
          distanceKm: dist,
          durationSec: durSec,
          avgHr: avgHr,
          maxHr: maxHr,
          notes: notes,
        );
      }
      if (mounted) {
        // Celebrate into the root overlay before the sheet closes, so the
        // flourish plays over the screen we return to.
        HapticFeedback.mediumImpact();
        Celebrate.burst(context);
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final planned = widget.plannedRun;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              planned != null
                  ? 'Log ${runTypeLabel(planned.type).toLowerCase()}'
                  : 'Log an extra run',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _distance,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Distance (km)', prefixIcon: Icon(Icons.straighten)),
                    validator: (v) {
                      final d = double.tryParse((v ?? '').trim());
                      if (d == null || d <= 0) return 'Enter distance';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _minutes,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Time (min)', prefixIcon: Icon(Icons.timer_outlined)),
                    validator: (v) {
                      final m = double.tryParse((v ?? '').trim());
                      if (m == null || m <= 0) return 'Enter time';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _avgHr,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                        labelText: 'Avg HR', prefixIcon: Icon(Icons.favorite_outline)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxHr,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Max HR'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(
                  labelText: 'Notes (optional)', prefixIcon: Icon(Icons.notes)),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_rounded),
              label: const Text('Save run'),
            ),
          ],
        ),
      ),
    );
  }
}
