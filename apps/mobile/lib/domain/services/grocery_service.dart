/// Service for building grocery lists from recipe ingredients.
///
/// Handles:
/// - Merging duplicate ingredients across recipes
/// - Categorizing items by aisle (produce, dairy, pantry, etc.)
/// - Unit normalization for intelligent merging
library;

import '../models/grocery.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';

/// Builds a merged, categorized grocery list from selected recipes.
///
/// This is a pure function with no side effects -- all logic runs
/// client-side from the recipe data already in memory.
class GroceryService {
  /// Creates a grocery service instance.
  const GroceryService();

  /// Builds a grocery list from the given [recipes].
  ///
  /// Merges duplicate ingredients (same name + compatible units),
  /// categorizes each item, and returns a sorted list grouped by category.
  GroceryList buildGroceryList(List<ResolvedRecipe> recipes) {
    final Map<String, _MergeAccumulator> merged =
        <String, _MergeAccumulator>{};

    for (final ResolvedRecipe recipe in recipes) {
      for (final ResolvedIngredient ingredient in recipe.ingredients) {
        final ParsedIngredient parsed = ingredient.parsed;
        final String key = _mergeKey(parsed);

        if (merged.containsKey(key)) {
          merged[key] = merged[key]!.addFrom(parsed, recipe.id);
        } else {
          merged[key] = _MergeAccumulator(
            name: parsed.name,
            quantity: parsed.quantity,
            unit: parsed.unit,
            recipeIds: <String>[recipe.id],
          );
        }
      }
    }

    final List<GroceryItem> items = merged.values.map(
      (_MergeAccumulator acc) {
        return GroceryItem(
          name: acc.name,
          quantity: acc.quantity,
          unit: acc.unit,
          category: categorizeIngredient(acc.name),
          recipeIds: acc.recipeIds,
        );
      },
    ).toList();

    // Sort by category then by name
    items.sort((GroceryItem a, GroceryItem b) {
      final int catCmp = a.category.index.compareTo(b.category.index);
      if (catCmp != 0) return catCmp;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return GroceryList(
      items: items,
      recipeIds: recipes.map((ResolvedRecipe r) => r.id).toList(),
    );
  }

  /// Generates a merge key for an ingredient.
  ///
  /// Ingredients with the same name and compatible units are merged.
  String _mergeKey(ParsedIngredient parsed) {
    final String normalizedName = parsed.name.toLowerCase().trim();
    final String normalizedUnit =
        _normalizeUnit(parsed.unit?.toLowerCase().trim() ?? '');
    return '$normalizedName|$normalizedUnit';
  }

  /// Normalizes common unit variations to a canonical form.
  static String _normalizeUnit(String unit) {
    return switch (unit) {
      'cups' || 'c' => 'cup',
      'tbsps' || 'tablespoons' || 'tablespoon' || 'tbs' => 'tbsp',
      'tsps' || 'teaspoons' || 'teaspoon' => 'tsp',
      'ozs' || 'ounces' || 'ounce' => 'oz',
      'lbs' || 'pounds' || 'pound' => 'lb',
      'grams' || 'gram' || 'gms' => 'g',
      'mls' || 'milliliters' || 'milliliter' || 'millilitres' => 'ml',
      'liters' || 'liter' || 'litres' || 'litre' => 'l',
      'cloves' => 'clove',
      'pieces' || 'pcs' => 'piece',
      'slices' => 'slice',
      final String other => other,
    };
  }

  /// Categorizes an ingredient by name into a grocery category.
  ///
  /// Uses simple heuristic keyword matching. Categories are intentionally
  /// broad -- this is a UX convenience, not a perfect taxonomy.
  static GroceryCategory categorizeIngredient(String name) {
    final String lower = name.toLowerCase();

    // Produce
    if (_matchesAny(lower, _produceKeywords)) {
      return GroceryCategory.produce;
    }

    // Dairy
    if (_matchesAny(lower, _dairyKeywords)) {
      return GroceryCategory.dairy;
    }

    // Meat
    if (_matchesAny(lower, _meatKeywords)) {
      return GroceryCategory.meat;
    }

    // Bakery
    if (_matchesAny(lower, _bakeryKeywords)) {
      return GroceryCategory.bakery;
    }

    // Frozen
    if (_matchesAny(lower, _frozenKeywords)) {
      return GroceryCategory.frozen;
    }

    // Pantry (default for most dry goods, spices, etc.)
    if (_matchesAny(lower, _pantryKeywords)) {
      return GroceryCategory.pantry;
    }

    // Default to pantry for unknown items
    return GroceryCategory.pantry;
  }

  static bool _matchesAny(String text, List<String> keywords) {
    for (final String keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }
}

/// Human-readable label for a [GroceryCategory].
String groceryCategoryLabel(GroceryCategory category) {
  return switch (category) {
    GroceryCategory.produce => 'Produce',
    GroceryCategory.dairy => 'Dairy & Eggs',
    GroceryCategory.meat => 'Meat & Seafood',
    GroceryCategory.pantry => 'Pantry',
    GroceryCategory.frozen => 'Frozen',
    GroceryCategory.bakery => 'Bakery',
    GroceryCategory.other => 'Other',
  };
}

/// Formats a grocery item's quantity and unit for display.
String formatGroceryQuantity(GroceryItem item) {
  final StringBuffer buf = StringBuffer();
  if (item.quantity != null) {
    final double qty = item.quantity!;
    if (qty == qty.toInt().toDouble()) {
      buf.write(qty.toInt());
    } else {
      buf.write(qty.toStringAsFixed(1));
    }
    if (item.unit != null && item.unit!.isNotEmpty) {
      buf.write(' ${item.unit}');
    }
    buf.write(' ');
  }
  buf.write(item.name);
  return buf.toString();
}

/// Accumulator for merging ingredient quantities.
class _MergeAccumulator {
  _MergeAccumulator({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.recipeIds,
  });

  final String name;
  final double? quantity;
  final String? unit;
  final List<String> recipeIds;

  /// Merges another instance of this ingredient.
  _MergeAccumulator addFrom(ParsedIngredient parsed, String recipeId) {
    double? newQty = quantity;
    if (quantity != null && parsed.quantity != null) {
      newQty = quantity! + parsed.quantity!;
    } else if (parsed.quantity != null) {
      newQty = parsed.quantity;
    }

    return _MergeAccumulator(
      name: name,
      quantity: newQty,
      unit: unit ?? parsed.unit,
      recipeIds: <String>[...recipeIds, recipeId],
    );
  }
}

// Keyword lists for heuristic categorization
const List<String> _produceKeywords = <String>[
  'lettuce',
  'tomato',
  'onion',
  'garlic',
  'pepper',
  'carrot',
  'celery',
  'potato',
  'avocado',
  'cucumber',
  'spinach',
  'kale',
  'broccoli',
  'cauliflower',
  'zucchini',
  'squash',
  'mushroom',
  'corn',
  'pea',
  'bean sprout',
  'cabbage',
  'eggplant',
  'asparagus',
  'apple',
  'banana',
  'lemon',
  'lime',
  'orange',
  'berry',
  'berries',
  'strawberr',
  'blueberr',
  'raspberr',
  'mango',
  'pineapple',
  'grape',
  'melon',
  'peach',
  'pear',
  'ginger',
  'cilantro',
  'parsley',
  'basil',
  'mint',
  'dill',
  'rosemary',
  'thyme',
  'scallion',
  'shallot',
  'leek',
  'radish',
  'beet',
  'sweet potato',
  'jalape',
  'chili pepper',
  'bell pepper',
  'green onion',
];

const List<String> _dairyKeywords = <String>[
  'milk',
  'cream',
  'butter',
  'cheese',
  'yogurt',
  'sour cream',
  'egg',
  'whipping cream',
  'half and half',
  'half-and-half',
  'ricotta',
  'mozzarella',
  'parmesan',
  'cheddar',
  'feta',
  'goat cheese',
  'cream cheese',
  'cottage cheese',
  'mascarpone',
  'ghee',
];

const List<String> _meatKeywords = <String>[
  'chicken',
  'beef',
  'pork',
  'lamb',
  'turkey',
  'duck',
  'fish',
  'salmon',
  'tuna',
  'shrimp',
  'prawn',
  'crab',
  'lobster',
  'scallop',
  'bacon',
  'sausage',
  'ham',
  'steak',
  'ground beef',
  'ground turkey',
  'anchov',
  'tilapia',
  'cod',
  'halibut',
  'mahi',
  'clam',
  'mussel',
  'oyster',
  'veal',
  'bison',
  'venison',
];

const List<String> _pantryKeywords = <String>[
  'flour',
  'sugar',
  'salt',
  'oil',
  'vinegar',
  'soy sauce',
  'rice',
  'pasta',
  'noodle',
  'broth',
  'stock',
  'canned',
  'can of',
  'baking',
  'vanilla',
  'cocoa',
  'chocolate',
  'honey',
  'maple syrup',
  'molasses',
  'cornstarch',
  'yeast',
  'gelatin',
  'spice',
  'cumin',
  'paprika',
  'cinnamon',
  'nutmeg',
  'oregano',
  'turmeric',
  'chili powder',
  'cayenne',
  'black pepper',
  'white pepper',
  'sesame',
  'soy',
  'worcestershire',
  'ketchup',
  'mustard',
  'mayonnaise',
  'hot sauce',
  'sriracha',
  'teriyaki',
  'peanut butter',
  'jam',
  'jelly',
  'breadcrumb',
  'cracker',
  'chip',
  'nut',
  'almond',
  'walnut',
  'pecan',
  'pistachio',
  'cashew',
  'peanut',
  'coconut',
  'dried',
  'oat',
  'cereal',
  'lentil',
  'chickpea',
  'bean',
  'tomato sauce',
  'tomato paste',
  'crushed tomato',
  'diced tomato',
];

const List<String> _bakeryKeywords = <String>[
  'bread',
  'tortilla',
  'pita',
  'naan',
  'baguette',
  'roll',
  'bun',
  'croissant',
  'muffin',
  'bagel',
  'flatbread',
  'cornbread',
];

const List<String> _frozenKeywords = <String>[
  'frozen',
  'ice cream',
  'popsicle',
  'frozen yogurt',
];
