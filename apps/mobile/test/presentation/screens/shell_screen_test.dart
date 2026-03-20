/// Widget tests for the shell screen with bottom navigation.
library;

import 'package:dishy/presentation/providers/recipe_list_provider.dart';
import 'package:dishy/presentation/screens/shell_screen.dart';
import 'package:dishy/domain/models/recipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShellScreen', () {
    testWidgets('shows bottom navigation bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            recipeListProvider.overrideWith(
              () => _EmptyRecipeListNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: ShellScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('has three navigation destinations',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            recipeListProvider.overrideWith(
              () => _EmptyRecipeListNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: ShellScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Recipes'), findsOneWidget);
      expect(find.text('Grocery'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('starts on recipes tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            recipeListProvider.overrideWith(
              () => _EmptyRecipeListNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: ShellScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Dishy is the title of the recipes tab
      expect(find.text('Dishy'), findsOneWidget);
    });

    testWidgets('switches to grocery tab on tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            recipeListProvider.overrideWith(
              () => _EmptyRecipeListNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: ShellScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Grocery'));
      await tester.pumpAndSettle();

      expect(find.text('Grocery List'), findsOneWidget);
    });

    testWidgets('switches to profile tab on tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            recipeListProvider.overrideWith(
              () => _EmptyRecipeListNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: ShellScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Profile tab shows "Sign Out" button
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('preserves state across tab switches',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            recipeListProvider.overrideWith(
              () => _EmptyRecipeListNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: ShellScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to grocery tab
      await tester.tap(find.text('Grocery'));
      await tester.pumpAndSettle();

      // Switch back to recipes
      await tester.tap(find.text('Recipes'));
      await tester.pumpAndSettle();

      // Recipes tab should still show properly
      expect(find.text('Dishy'), findsOneWidget);
    });
  });
}

class _EmptyRecipeListNotifier extends RecipeListNotifier {
  @override
  Future<List<ResolvedRecipe>> build() async => <ResolvedRecipe>[];
}
