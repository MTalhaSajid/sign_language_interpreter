import 'package:boilerplate_flutter/features/home/view/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
