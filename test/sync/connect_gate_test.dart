import 'package:flutter_test/flutter_test.dart';
import 'package:paceshift/domain/models/app_settings.dart';
import 'package:paceshift/presentation/router.dart';

/// The one-time "connect your health data" gate in the router.
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

  test('a fresh plan sends the user to the connect step', () {
    expect(redirect('/today'), '/connect');
  });

  test('the connect step is not a redirect loop', () {
    expect(redirect('/connect'), isNull);
  });

  test('once asked, the gate releases to Today', () {
    expect(redirect('/connect', settings: asked), '/today');
    expect(redirect('/today', settings: asked), isNull);
  });

  test('platforms without a health store never see the connect step', () {
    expect(redirect('/today', supportsHealth: false), isNull);
    expect(redirect('/connect', supportsHealth: false), '/today');
  });

  test('the gate waits for settings rather than flashing on a null', () {
    expect(redirect('/today', settings: null), isNull);
  });

  test('onboarding still takes precedence over the connect step', () {
    expect(redirect('/today', hasPlan: false), '/onboarding');
    expect(redirect('/connect', hasPlan: false), '/onboarding');
  });

  test('the splash still takes precedence over everything', () {
    expect(redirect('/today', planLoading: true), '/loading');
    expect(redirect('/loading', planLoading: true), isNull);
  });

  test('an answered gate still forwards the splash and onboarding to Today', () {
    expect(redirect('/loading', settings: asked), '/today');
    expect(redirect('/onboarding', settings: asked), '/today');
  });

  test('deep links are left alone once the gate is answered', () {
    expect(redirect('/sync', settings: asked), isNull);
    expect(redirect('/run/12', settings: asked), isNull);
  });
}
