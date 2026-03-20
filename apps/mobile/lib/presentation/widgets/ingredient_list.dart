/// Ingredient list widget for displaying parsed and resolved ingredients.
///
/// Shows ingredients with their parsed structure (quantity, unit, name,
/// preparation) and subtly indicates the resolution status (matched,
/// fuzzy matched, or unmatched).
library;

import 'package:flutter/material.dart';

import '../../domain/models/ingredient.dart';

/// A widget that displays a list of resolved ingredients.
///
/// Each ingredient shows its parsed quantity, unit, name, and preparation.
/// A subtle indicator shows the resolution status for each item.
class IngredientList extends StatelessWidget {
  /// Creates an ingredient list for the given [ingredients].
  const IngredientList({
    required this.ingredients,
    super.key,
  });

  /// The resolved ingredients to display.
  final List<ResolvedIngredient> ingredients;

  @override
  Widget build(BuildContext context) {
    if (ingredients.isEmpty) {
      return const Text(
        'No ingredients listed.',
        style: TextStyle(fontSize: 14, color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ingredients.map(_buildIngredientRow).toList(),
    );
  }

  Widget _buildIngredientRow(ResolvedIngredient ingredient) {
    final ParsedIngredient parsed = ingredient.parsed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Resolution status indicator
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _ResolutionDot(resolution: ingredient.resolution),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _IngredientText(parsed: parsed),
          ),
        ],
      ),
    );
  }
}

/// Displays the formatted ingredient text with structured components.
class _IngredientText extends StatelessWidget {
  const _IngredientText({required this.parsed});

  final ParsedIngredient parsed;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(fontSize: 16),
        children: <InlineSpan>[
          // Quantity
          if (parsed.quantity != null)
            TextSpan(
              text: '${_formatQuantity(parsed.quantity!)} ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          // Unit
          if (parsed.unit != null)
            TextSpan(
              text: '${parsed.unit} ',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          // Name
          TextSpan(text: parsed.name),
          // Preparation
          if (parsed.preparation != null)
            TextSpan(
              text: ', ${parsed.preparation}',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  /// Formats a quantity for display, removing trailing .0.
  String _formatQuantity(double qty) {
    if (qty == qty.toInt().toDouble()) {
      return qty.toInt().toString();
    }
    return qty.toString();
  }
}

/// A small dot indicating the resolution status of an ingredient.
///
/// - Green dot: matched (exact match in food database)
/// - Orange dot: fuzzy matched (approximate match)
/// - Grey dot: unmatched (no match found)
class _ResolutionDot extends StatelessWidget {
  const _ResolutionDot({required this.resolution});

  final IngredientResolution resolution;

  @override
  Widget build(BuildContext context) {
    final (Color color, String tooltip) = switch (resolution) {
      IngredientResolutionMatched() => (Colors.green, 'Matched'),
      IngredientResolutionFuzzyMatched() => (Colors.orange, 'Approximate match'),
      IngredientResolutionUnmatched() => (Colors.grey, 'Not matched'),
    };

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
