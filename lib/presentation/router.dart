import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/motion.dart';
import '../data/health/health_service.dart';
import '../domain/models/app_settings.dart';
import 'genui/ask_coach_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'plan/plan_screen.dart';
import 'providers/providers.dart';
import 'run_detail/run_detail_screen.dart';
import 'settings/about_screen.dart';
import 'settings/data_settings_screen.dart';
import 'settings/edit_plan_screen.dart';
import 'settings/settings_screen.dart';
import 'settings/training_settings_screen.dart';
import 'stats/stats_screen.dart';
import 'sync/connect_health_screen.dart';
import 'sync/sync_screen.dart';
import 'today/today_screen.dart';
import 'widgets/app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// The router's gating rules, as a pure function so they can be tested without
/// a live platform, database, or navigator. Returns the location to redirect
/// to, or null to stay put.
String? resolveRedirect({
  required String location,
  required bool planLoading,
  required bool hasPlan,
  required AppSettings? settings,
  required bool supportsHealth,
}) {
  if (planLoading) return location == '/loading' ? null : '/loading';
  if (!hasPlan) return location == '/onboarding' ? null : '/onboarding';

  // Health connect is **not** gated here any more.
  //
  // It used to be a forced full-screen step the moment a plan existed, so the
  // very first thing a new athlete saw after answering eight questions was a
  // screen headed "Your plan is ready" that showed them none of their plan and
  // asked for a sensitive health permission instead. Now they land on Today,
  // see the plan they just built, and the offer waits for them in the
  // attention queue — reachable at `/connect` whenever they want it.
  if (location == '/onboarding' || location == '/loading') return '/today';
  return null;
}

/// App router. Redirects to onboarding until an active plan exists, and shows a
/// brief splash while the active plan loads from disk.
final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(activePlanProvider, (prev, next) => refresh.value++);
  // The connect gate below keys off settings, so the redirect has to be
  // re-evaluated when they change — otherwise dismissing the screen wouldn't
  // release the gate.
  ref.listen(settingsProvider, (prev, next) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/today',
    refreshListenable: refresh,
    redirect: (context, state) {
      final planState = ref.read(activePlanProvider);
      return resolveRedirect(
        location: state.matchedLocation,
        planLoading: planState.isLoading && !planState.hasValue,
        hasPlan: planState.value != null,
        settings: ref.read(settingsProvider).value,
        supportsHealth: HealthService.isSupportedPlatform,
      );
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) => const _LoadingScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/run/:id',
        pageBuilder: (_, state) => sharedAxisPage(
          key: state.pageKey,
          child:
              RunDetailScreen(runId: int.parse(state.pathParameters['id']!)),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/sync',
        pageBuilder: (context, state) =>
            sharedAxisPage(key: state.pageKey, child: const SyncScreen()),
      ),
      GoRoute(
        path: '/connect',
        builder: (context, state) => const ConnectHealthScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/coach',
        pageBuilder: (context, state) =>
            sharedAxisPage(key: state.pageKey, child: const AskCoachScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/settings/plan',
        pageBuilder: (context, state) =>
            sharedAxisPage(key: state.pageKey, child: const EditPlanScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/settings/training',
        pageBuilder: (context, state) => sharedAxisPage(
            key: state.pageKey, child: const TrainingSettingsScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/settings/data',
        pageBuilder: (context, state) => sharedAxisPage(
            key: state.pageKey, child: const DataSettingsScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/settings/about',
        pageBuilder: (context, state) =>
            sharedAxisPage(key: state.pageKey, child: const AboutScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/today', builder: (context, state) => const TodayScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/plan', builder: (context, state) => const PlanScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/stats', builder: (context, state) => const StatsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/settings', builder: (context, state) => const SettingsScreen()),
          ]),
        ],
      ),
    ],
  );
});

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
