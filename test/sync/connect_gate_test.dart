import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/domain/models/app_settings.dart';
import 'package:paceshift/presentation/router.dart';

/// The router's gating rules.
///
/// The "connect your health data" step used to be a *gate* here: a forced
/// full-screen redirect the instant a plan existed. It isn't any more — asking
/// for a sensitive permission before the athlete has seen a single line of the
/// plan they just spent a minute building is the wrong trade, and the screen it
/// redirected to showed no plan content at all. The offer now lives in the
/// Today attention queue and `/connect` is reached deliberately.
///
/// These tests pin that down, so nobody reinstates the gate by accident.
void main() {
  const never = AppSettings();
  final asked = AppSettings(healthPromptedAt: DateTime(2026, 3, 2));

  String? redirect(
    String location, {
    bool planLoading = false,
    bool hasPlan = true,
    AppSettings? settings = never,
    bool supportsHealth = true,
  }) =>
      resolveRedirect(
        location: location,
        planLoading: planLoading,
        hasPlan: hasPlan,
        settings: settings,
        supportsHealth: supportsHealth,
      );

  test('a fresh plan lands on Today, not on a permission prompt', () {
    expect(redirect('/today'), isNull);
    expect(redirect('/onboarding'), '/today');
  });

  test('/connect is reachable on purpose and never bounces', () {
    expect(redirect('/connect'), isNull);
    expect(redirect('/connect', settings: asked), isNull);
    expect(redirect('/connect', supportsHealth: false), isNull);
  });

  test('having been asked changes no routing', () {
    expect(redirect('/today', settings: asked), isNull);
  });

  test('a null settings snapshot never redirects anywhere', () {
    expect(redirect('/today', settings: null), isNull);
  });

  test('onboarding takes precedence over everything below it', () {
    expect(redirect('/today', hasPlan: false), '/onboarding');
    expect(redirect('/connect', hasPlan: false), '/onboarding');
    expect(redirect('/onboarding', hasPlan: false), isNull);
  });

  test('the splash takes precedence over everything', () {
    expect(redirect('/today', planLoading: true), '/loading');
    expect(redirect('/loading', planLoading: true), isNull);
  });

  test('the splash and onboarding forward to Today once a plan exists', () {
    expect(redirect('/loading', settings: asked), '/today');
    expect(redirect('/onboarding', settings: asked), '/today');
  });

  test('deep links are left alone', () {
    expect(redirect('/sync', settings: asked), isNull);
    expect(redirect('/run/12', settings: asked), isNull);
    expect(redirect('/settings/plan', settings: asked), isNull);
  });
}
