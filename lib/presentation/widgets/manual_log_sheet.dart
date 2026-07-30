import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
import '../../core/errors.dart';
import '../../core/formatting.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/planned_run.dart';
import '../providers/providers.dart';
import 'celebration.dart';
import 'common.dart';

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
  String? _error;

  /// The exact planned distance behind the prefilled text. The field shows a
  /// value rounded to one display unit, so logging a run "as shown" would
  /// otherwise rewrite a 12.875 km target to 12.9.
  double? _prefilledKm;
  String? _prefilledText;

  /// Set once the athlete types, so a late-arriving units value can no longer
  /// overwrite their input.
  bool _edited = false;

  @override
  void initState() {
    super.initState();
    _prefilledKm = widget.plannedRun?.targetDistanceKm;
    _distance = TextEditingController();
    _minutes = TextEditingController(
      text: widget.plannedRun?.targetDurationMin?.toString() ?? '',
    );
    _applyPrefill(ref.read(unitsProvider));
  }

  /// Writes the planned distance into the field in [units].
  ///
  /// Called again whenever the units value changes. `unitsProvider` answers
  /// metric while the settings row is still loading, so prefilling once in
  /// [initState] showed an imperial athlete the raw kilometre figure.
  void _applyPrefill(UnitSystem units) {
    final km = _prefilledKm;
    if (km == null || _edited) return;
    _prefilledText = units.distanceValue(km);
    if (_distance.text != _prefilledText) _distance.text = _prefilledText!;
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
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(runRepositoryProvider);
    final units = ref.read(unitsProvider);
    final typed = _distance.text.trim();
    // The field is in the athlete's own units, so it must be converted back to
    // stored kilometres. Without this an imperial athlete logging a 13.1 mile
    // half marathon recorded 13.1 km, corrupting every total, chart, VDOT
    // estimate and race prediction downstream.
    final dist = typed == _prefilledText && _prefilledKm != null
        ? _prefilledKm!
        : units.fromDisplay(double.parse(typed));
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
    } catch (e) {
      // Without this the write could fail silently and the athlete would have
      // no idea whether their run was recorded.
      if (mounted) {
        setState(() => _error =
            friendlyError(e, fallback: 'We couldn’t save that run.'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final planned = widget.plannedRun;
    final theme = Theme.of(context);
    final units = ref.watch(unitsProvider);
    // Re-prefill if the settings row resolves after the first frame.
    ref.listen<UnitSystem>(unitsProvider, (_, next) => _applyPrefill(next));
    return Padding(
      padding: EdgeInsets.only(
        left: Space.screenH,
        right: Space.screenH,
        top: Space.xs,
        bottom: MediaQuery.of(context).viewInsets.bottom + Space.screenH,
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
            const SizedBox(height: Space.lg),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _distance,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                        labelText: 'Distance (${units.distanceLabel})',
                        prefixIcon: const Icon(Icons.straighten)),
                    onChanged: (_) => _edited = true,
                    validator: (v) {
                      final d = double.tryParse((v ?? '').trim());
                      if (d == null || d <= 0) {
                        return 'Enter distance in ${units.distanceLabel}';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: Space.md),
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
            const SizedBox(height: Space.md),
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
                const SizedBox(width: Space.md),
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
            const SizedBox(height: Space.md),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(
                  labelText: 'Notes (optional)', prefixIcon: Icon(Icons.notes)),
              maxLines: 2,
            ),
            if (_error != null) ...[
              const SizedBox(height: Space.md),
              SurfaceError(message: _error!, compact: true, onRetry: _save),
            ],
            const SizedBox(height: Space.xl),
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
