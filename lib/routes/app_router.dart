import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/app_shell.dart';
import '../screens/climate_screen.dart';
import '../screens/farm_form_screen.dart';
import '../screens/history_detail_screen.dart';
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/results_screen.dart';
import '../screens/splash_screen.dart';
import '../utils/constants.dart';

/// Rutas de la app. La redirección depende únicamente del estado de [AuthProvider]:
/// - unknown          -> /splash (mientras se valida la sesión guardada)
/// - unauthenticated  -> /login o /register
/// - authenticated    -> cualquier ruta privada (nunca splash/login/register)
class AppRouter {
  AppRouter._();

  static const _authRoutes = {'/login', '/register'};

  static String? redirect(AuthStatus status, String location) {
    final onSplash = location == '/splash';
    final onAuth = _authRoutes.contains(location);
    switch (status) {
      case AuthStatus.unknown:
        return onSplash ? null : '/splash';
      case AuthStatus.unauthenticated:
        return onAuth ? null : '/login';
      case AuthStatus.authenticated:
        return (onSplash || onAuth) ? '/home' : null;
    }
  }

  static GoRouter create(AuthProvider auth) => GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) => redirect(auth.status, state.matchedLocation),
    errorBuilder: (context, state) => const _NotFoundScreen(),
    routes: [
      GoRoute(path: '/splash', pageBuilder: (c, s) => _fade(s, const SplashScreen())),
      GoRoute(path: '/login', pageBuilder: (c, s) => _fade(s, const LoginScreen())),
      GoRoute(path: '/register', pageBuilder: (c, s) => _fade(s, const RegisterScreen())),
      GoRoute(path: '/recommend', pageBuilder: (c, s) => _slideUp(s, const FarmFormScreen())),
      GoRoute(path: '/results', pageBuilder: (c, s) => _slideUp(s, const ResultsScreen())),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/home', builder: (c, s) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (c, s) => const HistoryScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    pageBuilder: (c, s) {
                      final id = int.tryParse(s.pathParameters['id'] ?? '');
                      return _fade(s, id == null ? const _NotFoundScreen() : HistoryDetailScreen(id: id));
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/climate', builder: (c, s) => const ClimateScreen())],
          ),
        ],
      ),
    ],
  );

  static Page<void> _fade(GoRouterState state, Widget child) => CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppDurations.normal,
    transitionsBuilder: (context, animation, secondary, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: AppDurations.curve),
      child: child,
    ),
  );

  static Page<void> _slideUp(GoRouterState state, Widget child) => CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppDurations.slow,
    reverseTransitionDuration: AppDurations.normal,
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(parent: animation, curve: AppDurations.curve);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.explore_off_rounded, size: 56),
            const SizedBox(height: AppSpacing.md),
            const Text('No encontramos esta pantalla.', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: () => context.go('/home'), child: const Text('Ir al inicio')),
          ],
        ),
      ),
    ),
  );
}
