/// Dishy — Recipe Capture & Cooking App.
///
/// Entry point for the Flutter application. Wraps the app in a
/// [ProviderScope] to enable Riverpod state management throughout
/// the widget tree.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/auth/auth_provider.dart';

/// Application entry point.
///
/// Initializes Flutter bindings and launches the app inside a
/// [ProviderScope] so all Riverpod providers are available.
/// Clerk authentication is initialized automatically on startup.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final ProviderContainer container = ProviderContainer();

  // Initialize Clerk auth asynchronously. The auth guard will show
  // a loading state until initialization completes.
  container.read(authProvider.notifier).initialize(
        AppConstants.clerkPublishableKey,
      );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DishyApp(),
    ),
  );
}
