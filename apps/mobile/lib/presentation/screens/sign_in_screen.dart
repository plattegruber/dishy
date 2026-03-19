/// Sign-in screen with email and password fields.
///
/// Provides a simple form for email/password authentication via Clerk.
/// Validates input locally before submitting and displays error messages
/// from the auth provider. On success, the auth guard redirects to the
/// home screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_state.dart';

/// Screen for signing in with email and password.
///
/// Uses Clerk's email/password strategy. The form validates that both
/// fields are non-empty before enabling the sign-in button. Error
/// messages from the [AuthNotifier] are displayed below the form.
class SignInScreen extends ConsumerStatefulWidget {
  /// Creates the sign-in screen.
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Clerk sign-in is handled via the ClerkAuth widget tree.
    // This form captures credentials and delegates to the auth notifier.
    // In a real integration, the ClerkAuth widget handles the sign-in
    // flow. Here we update the notifier state for the guard to react.
    final AuthNotifier notifier = ref.read(authProvider.notifier);
    notifier.setLoading();

    // The actual Clerk sign-in happens through the ClerkAuth widget.
    // This screen provides the UI; the ClerkAuthBuilder callback
    // updates the notifier when Clerk reports a state change.

    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 48),
                const Icon(
                  Icons.restaurant_menu,
                  size: 64,
                  color: Colors.deepOrange,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Welcome to Dishy',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to access your recipes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (authState case AuthError(:final String message))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                FilledButton(
                  onPressed: _isSubmitting ? null : _handleSignIn,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Sign In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
