/// Dishy — Recipe Capture & Cooking App.
///
/// Entry point for the Flutter application. Wraps the app in a
/// [ProviderScope] to enable Riverpod state management throughout
/// the widget tree, and initialises the Clerk authentication SDK.
library;

import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/auth/auth_provider.dart';

/// Application entry point.
///
/// Initializes Flutter bindings and launches the app inside a
/// [ProviderScope] so all Riverpod providers are available. The
/// [ClerkAuth] widget wraps the app to provide Clerk authentication
/// context throughout the widget tree.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ProviderScope(
      child: Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          final String publishableKey =
              ref.watch(clerkPublishableKeyProvider);

          // When no publishable key is configured, run without Clerk.
          // This enables running tests and development without a Clerk
          // account.
          if (publishableKey.isEmpty) {
            return const DishyApp();
          }

          return ClerkAuth(
            config: ClerkAuthConfig(publishableKey: publishableKey),
            child: const DishyApp(),
          );
        },
      ),
    ),
  );
}
