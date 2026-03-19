/// Root application widget with Material theming and GoRouter navigation.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'presentation/screens/home_screen.dart';

/// Top-level router configuration.
///
/// Defines all application routes. Currently only the home route is
/// available; additional routes will be added as features are built.
final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
  ],
);

/// Root widget for the Dishy application.
///
/// Sets up [MaterialApp.router] with the GoRouter instance and the
/// application theme. This widget sits directly under [ProviderScope]
/// in the widget tree.
class DishyApp extends StatelessWidget {
  /// Creates the root application widget.
  const DishyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Dishy',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        useMaterial3: true,
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
