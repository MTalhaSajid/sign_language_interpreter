import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sign_language_interpreter/features/video_call/controller/call_controller.dart';
import 'package:sign_language_interpreter/features/video_call/service/call_service.dart';
import 'package:sign_language_interpreter/features/video_call/view/call_screen.dart';
import '../../features/auth/controller/auth_controller.dart';
import '../../features/auth/view/login_screen.dart';
import '../../features/auth/view/register_screen.dart';
import '../../features/home/view/home_screen.dart';
import '../../features/settings/view/setting_screen.dart';
import '../../features/splash/view/splash_screen.dart';
import '../../features/interpreter/controller/interpreter_controller.dart';
import '../../features/interpreter/view/interpreter_screen.dart';
import '../../features/alphabet/view/alphabet_screen.dart';
import '../../core/di/service_locator.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter() {
  final authController = sl<AuthController>();

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/splash',
    refreshListenable: authController,
    redirect: (context, state) {
      final loggedIn = authController.isLoggedIn;
      final isSplash = state.matchedLocation == '/splash';
      final isLoginRoute = state.matchedLocation == '/login';
      final isRegisterRoute = state.matchedLocation == '/register';

      if (isSplash) return null;
      if (!loggedIn && (isLoginRoute || isRegisterRoute)) return null;
      if (!loggedIn) return '/login';
      if (loggedIn && (isLoginRoute || isRegisterRoute)) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingScreen(),
      ),
      GoRoute(
        path: '/interpreter',
        builder: (context, state) =>
            ChangeNotifierProvider<InterpreterController>(
          create: (_) => sl<InterpreterController>(),
          child: const InterpreterScreen(),
        ),
      ),
      GoRoute(
        path: '/alphabet',
        builder: (context, state) => const AlphabetScreen(),
      ),
      GoRoute(
        path: '/word-to-sign',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Word to Sign — Coming Soon')),
        ),
      ),
      GoRoute(
        path: '/sign-to-word',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Sign to Word — Coming Soon')),
        ),
      ),

      // ── Video call routes ──────────────────────────────────────────────────
      GoRoute(
        path: '/video-call',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => CallController(CallService()),
          child: const CallScreen(channelId: '', isIncoming: false),
        ),
      ),
      GoRoute(
        path: '/call/:channelId',
        builder: (context, state) {
          final channelId = state.pathParameters['channelId']!;
          final isIncoming =
              state.uri.queryParameters['incoming'] == 'true';
          return ChangeNotifierProvider(
            create: (_) => CallController(CallService()),
            child: CallScreen(
              channelId: channelId,
              isIncoming: isIncoming,
            ),
          );
        },
      ),
    ],
  );
}