import 'package:flutter/material.dart';

import '../../../core/design.dart';
import '../../../core/formatting.dart';
import '../../../domain/models/enums.dart';
import '../plan_filter.dart';

/// A horizontally scrolling row of [FilterChip]s that narrow the week list.
///
/// Week view only — it is hidden in month view rather than half-applied to a
/// grid. Driven entirely by [PlanFilter]; mutating a chip calls [onChanged] with
/// a new filter.
class PlanFilterBar extends StatelessWidget {
  const PlanFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
    this.showRunsOnly = false,
  });

  final PlanFilter filter;
  final ValueChanged<PlanFilter> onChanged;

  /// Whether to offer the "Runs only" chip.
  ///
  /// `PlanGenerator` only ever emits running sessions — a rest day is the
  /// *absence* of a run, not a `RunType.rest` row — so on a generated plan the
  /// chip would be a control that visibly does nothing. The caller passes true
  /// only when the plan actually contains a non-run session, which keeps
  /// [PlanFilter.runsOnly] useful if the engine ever starts scheduling them.
  final bool showRunsOnly;

  @override
  Widget build(BuildContext context) {
    // Wrap, not a horizontal scroll view: at 400 logical pixels the last chip
    // sat entirely off-screen with no affordance, and a horizontal scroller
    // nested in the vertical plan list also competes for the drag gesture.
    // Wrapping keeps every control visible and tappable at any text scale.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.screenH),
      child: Wrap(
        spacing: Space.sm,
        runSpacing: Space.sm,
        children: [
          if (showRunsOnly)
            _toggle(
              context,
              label: 'Runs only',
              selected: filter.runsOnly,
              onSelected: (v) => onChanged(filter.copyWith(runsOnly: v)),
            ),
          _toggle(
            context,
            label: 'Remaining',
            selected: filter.remainingOnly,
            onSelected: (v) =>
                onChanged(filter.copyWith(remainingOnly: v)),
          ),
          _typeToggle(context, RunType.easy),
          _typeToggle(context, RunType.steady),
          _typeToggle(context, RunType.long),
        ],
      ),
    );
  }

  Widget _toggle(
    BuildContext context, {
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) =>
      FilterChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: onSelected,
      );

  Widget _typeToggle(BuildContext context, RunType type) => _toggle(
        context,
        label: runTypeLabel(type).replaceAll(' run', ''),
        selected: filter.types.contains(type),
        onSelected: (v) => onChanged(filter.copyWith(
          types: _withType(filter.types, type, v),
        )),
      );

  /// Immutably add/remove a run type from the set.
  Set<RunType> _withType(Set<RunType> types, RunType type, bool add) {
    final next = Set<RunType>.from(types);
    if (add) {
      next.add(type);
    } else {
      next.remove(type);
    }
    return next;
  }
}
