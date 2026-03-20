/// Profile/Settings screen placeholder.
///
/// Shows the user's profile information and provides a sign-out button.
/// This is a placeholder for future settings and account management.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_state.dart';

/// Profile screen with user info and sign-out.
///
/// Displays the authenticated user's email and user ID, plus a
/// sign-out button. Placeholder for future settings functionality.
class ProfileScreen extends ConsumerWidget {
  /// Creates the profile screen.
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 32),
            CircleAvatar(
              radius: 48,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 48,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            if (authState case AuthAuthenticated(:final String? email))
              Text(
                email ?? 'No email',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            const SizedBox(height: 8),
            if (authState case AuthAuthenticated(:final String userId))
              Text(
                'ID: $userId',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).setUnauthenticated();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Dishy v0.1.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
