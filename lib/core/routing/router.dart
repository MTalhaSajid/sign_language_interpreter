import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/controller/auth_controller.dart';
import '../../features/auth/view/login_screen.dart';
import '../../features/home/view/home_screen.dart';
import '../../features/settings/view/setting_screen.dart';
import '../../core/di/service_locator.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// The [AuthController] is used as a [refreshListenable] so the guard
/// re-evaluates on every login/logout event.
GoRouter buildRouter() {
  final authController = sl<AuthController>();

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    refreshListenable: authController,
    redirect: (context, state) {
      final loggedIn = authController.isLoggedIn;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!loggedIn && !isLoginRoute) return '/login';
      if (loggedIn && isLoginRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingScreen(),
      ),
    ],
  );
}
