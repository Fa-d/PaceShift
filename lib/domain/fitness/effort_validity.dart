/// Plausibility guards for completed-effort data.
///
/// **Pure** — no Flutter/IO. Synced workouts can carry garbage (GPS spikes,
/// auto-paused sessions with real distance but a few seconds of elapsed time,
/// unit glitches). Left unchecked, one such record inflates the VDOT estimate
/// and yields an absurdly fast race prediction. These bounds reject the
/// impossible while keeping legitimately easy/slow efforts.
library;

/// Loosest sanity bound: the record describes a *physically possible* human
/// activity. Used at import time so walks/hikes (which can be slow) still pass,
/// while obviously corrupt records are dropped before they ever hit the DB.
///
/// Rejects pace faster than ~2:00/km (≈ 30 km/h, beyond any sustained human
/// movement) and absurd distance/duration magnitudes.
bool isPhysicallyPlausibleEffort({
  required double distanceKm,
  required int durationSec,
}) {
  if (distanceKm <= 0 || durationSec <= 0) return false;
  if (distanceKm > 500) return false; // beyond an ultra; almost certainly bad.
  if (durationSec > 60 * 60 * 48) return false; // > 48 h.
  final paceSecPerKm = durationSec / distanceKm;
  return paceSecPerKm >= 120; // not faster than 2:00/km.
}

/// Stricter bound for treating an effort as a *running* fitness signal: pace
/// within a human running range (~2:30–15:00 /km). Used by the fitness
/// estimator so a glitchy run can't dominate the VDOT high-water mark.
bool isPlausibleRunningEffort({
  required double distanceKm,
  required int durationSec,
}) {
  if (distanceKm <= 0 || durationSec <= 0) return false;
  final paceSecPerKm = durationSec / distanceKm;
  return paceSecPerKm >= 150 && paceSecPerKm <= 900;
}
