/// Grocery list domain model for SPEC §15 UX surfaces.
///
/// Supports merging duplicate ingredients from multiple recipes,
/// categorizing items by aisle/type, and tracking checked-off state.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'grocery.freezed.dart';
part 'grocery.g.dart';

/// A category for grouping grocery items by aisle/type.
enum GroceryCategory {
  /// Fresh fruits and vegetables.
  produce,

  /// Milk, cheese, yogurt, eggs, butter.
  dairy,

  /// Fresh and frozen meats, poultry, fish.
  meat,

  /// Shelf-stable items: flour, sugar, oil, canned goods, spices.
  pantry,

  /// Frozen foods.
  frozen,

  /// Bread, tortillas, baked goods.
  bakery,

  /// Items that don't fit other categories.
  other,
}

/// A single item on the grocery list.
///
/// Represents a merged ingredient across one or more recipes.
@freezed
class GroceryItem with _$GroceryItem {
  const factory GroceryItem({
    /// Display name of the ingredient.
    required String name,

    /// Total quantity after merging (may be null if not parseable).
    double? quantity,

    /// Unit of measurement.
    String? unit,

    /// The category for aisle grouping.
    required GroceryCategory category,

    /// IDs of recipes this ingredient came from.
    required List<String> recipeIds,

    /// Whether the item has been checked off.
    @Default(false) bool checked,
  }) = _GroceryItem;

  factory GroceryItem.fromJson(Map<String, dynamic> json) =>
      _$GroceryItemFromJson(json);
}

/// The full grocery list with items grouped by category.
@freezed
class GroceryList with _$GroceryList {
  const factory GroceryList({
    /// All items in the grocery list, grouped by category.
    required List<GroceryItem> items,

    /// Recipe IDs that contributed to this list.
    required List<String> recipeIds,
  }) = _GroceryList;

  factory GroceryList.fromJson(Map<String, dynamic> json) =>
      _$GroceryListFromJson(json);
}
