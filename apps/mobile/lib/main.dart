/// Dishy — Recipe Capture & Cooking App.
///
/// Entry point for the Flutter application. Wraps the app in a
/// [ProviderScope] to enable Riverpod state management throughout
/// the widget tree.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// Application entry point.
///
/// Initializes Flutter bindings and launches the app inside a
/// [ProviderScope] so all Riverpod providers are available.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: DishyApp(),
    ),
  );
}
