/// Home screen — the main landing page of the Dishy app.
///
/// Displays the app title and a placeholder message. This will evolve
/// into the recipe grid view as the recipe capture feature is built.
library;

import 'package:flutter/material.dart';

/// Primary screen shown when the app launches.
///
/// Currently displays a centered title and subtitle. Future iterations
/// will replace this with the recipe grid (SPEC section 15).
class HomeScreen extends StatelessWidget {
  /// Creates the home screen widget.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dishy'),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Colors.deepOrange,
            ),
            SizedBox(height: 16),
            Text(
              'Welcome to Dishy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your recipes, beautifully captured.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
