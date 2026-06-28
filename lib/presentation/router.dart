import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'genui/ask_coach_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'plan/plan_screen.dart';
import 'providers/providers.dart';
import 'run_detail/run_detail_screen.dart';
import 'settings/settings_screen.dart';
import 'stats/stats_screen.dart';
import 'sync/sync_screen.dart';
import 'today/today_screen.dart';
import 'widgets/app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// App router. Redirects to onboarding until an active plan exists, and shows a
/// brief splash while the active plan loads from disk.
final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(activePlanProvider, (prev, next) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/today',
    refreshListenable: refresh,
    redirect: (context, state) {
      final planState = ref.read(activePlanProvider);
      final loc = state.matchedLocation;

      if (planState.isLoading && !planState.hasValue) {
        return loc == '/loading' ? null : '/loading';
      }
      final hasPlan = planState.value != null;
      if (!hasPlan) {
        return loc == '/onboarding' ? null : '/onboarding';
      }
      if (loc == '/onboarding' || loc == '/loading') return '/today';
      return null;
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
        builder: (_, state) =>
            RunDetailScreen(runId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/sync',
        builder: (context, state) => const SyncScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/coach',
        builder: (context, state) => const AskCoachScreen(),
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
