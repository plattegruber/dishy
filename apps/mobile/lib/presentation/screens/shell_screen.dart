/// Shell screen with bottom navigation bar.
///
/// Provides the top-level navigation structure with three tabs:
/// - Recipes (home grid)
/// - Grocery List
/// - Profile/Settings
///
/// Uses [IndexedStack] to preserve state across tab switches.
library;

import 'package:flutter/material.dart';

import 'grocery_list_screen.dart';
import 'profile_screen.dart';
import 'recipe_list_screen.dart';

/// Main shell screen wrapping the three primary tabs.
///
/// The bottom navigation bar provides switching between:
/// 1. Recipes -- the home recipe grid
/// 2. Grocery List -- consolidated shopping list
/// 3. Profile -- user settings and sign-out
class ShellScreen extends StatefulWidget {
  /// Creates the shell screen.
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _currentIndex = 0;

  static const List<Widget> _tabs = <Widget>[
    RecipeListScreen(),
    GroceryListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Recipes',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Grocery',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
