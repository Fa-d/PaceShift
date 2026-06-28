import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

/// Whether the user has PaceShift Pro.
///
/// Truth is the backend entitlement (updated by the RevenueCat webhook and
/// surfaced on the authenticated user). A local override lets a just-completed
/// sandbox/real purchase reflect immediately before the next profile refresh.
class ProStatus extends Notifier<bool> {
  bool? _override;

  @override
  bool build() {
    final user = ref.watch(currentUserProvider);
    return _override ?? (user?.proEntitled ?? false);
  }

  /// Optimistically mark Pro active after a successful purchase.
  void grantLocally() {
    _override = true;
    state = true;
  }

  /// Clear the local override (e.g. on sign-out) and fall back to server truth.
  void reset() {
    _override = null;
    ref.invalidateSelf();
  }
}

final proStatusProvider = NotifierProvider<ProStatus, bool>(ProStatus.new);
