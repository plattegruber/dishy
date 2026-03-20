/// Nutrition facts card widget for displaying recipe macro information.
///
/// Shows a clean card with calories, protein, carbs, and fat values.
/// Supports per-recipe and per-serving toggle and displays a status
/// badge indicating whether the nutrition data is calculated, estimated,
/// or unavailable.
library;

import 'package:flutter/material.dart';

import '../../domain/models/nutrition.dart';

/// A card widget displaying nutrition macro information.
///
/// Shows calories, protein, carbs, and fat in a clean layout.
/// The card adapts its display based on the [NutritionStatus]:
/// - `calculated`: Green badge, full macro display
/// - `estimated`: Orange badge, full macro display with note
/// - `unavailable`/`pending`: Grey badge, placeholder message
class NutritionCard extends StatefulWidget {
  /// Creates a nutrition card for the given [nutrition] data.
  const NutritionCard({
    required this.nutrition,
    this.servings,
    super.key,
  });

  /// The nutrition computation data to display.
  final NutritionComputation nutrition;

  /// Number of servings (enables per-serving toggle when non-null).
  final int? servings;

  @override
  State<NutritionCard> createState() => _NutritionCardState();
}

class _NutritionCardState extends State<NutritionCard> {
  bool _showPerServing = false;

  @override
  Widget build(BuildContext context) {
    final NutritionStatus status = widget.nutrition.status;
    final bool hasData =
        status == NutritionStatus.calculated || status == NutritionStatus.estimated;
    final bool canToggle =
        hasData && widget.nutrition.perServing != null && widget.servings != null;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header row with title and status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Nutrition Facts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 12),

            if (hasData) ...<Widget>[
              // Per-recipe / per-serving toggle
              if (canToggle)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ToggleRow(
                    showPerServing: _showPerServing,
                    servings: widget.servings,
                    onToggle: (bool value) {
                      setState(() {
                        _showPerServing = value;
                      });
                    },
                  ),
                ),

              // Macro display
              _MacroRow(
                facts: _showPerServing && widget.nutrition.perServing != null
                    ? widget.nutrition.perServing!
                    : widget.nutrition.perRecipe,
              ),

              // Estimated note
              if (status == NutritionStatus.estimated)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Some ingredients could not be matched. Values are estimated.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
            ] else ...<Widget>[
              const Text(
                'Nutrition data is not yet available for this recipe.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Displays the nutrition status as a colored badge.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final NutritionStatus status;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (status) {
      NutritionStatus.calculated => ('Calculated', Colors.green),
      NutritionStatus.estimated => ('Estimated', Colors.orange),
      NutritionStatus.pending => ('Pending', Colors.grey),
      NutritionStatus.unavailable => ('Unavailable', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// A toggle row for switching between per-recipe and per-serving display.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.showPerServing,
    required this.servings,
    required this.onToggle,
  });

  final bool showPerServing;
  final int? servings;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _ToggleOption(
          label: 'Per recipe',
          isSelected: !showPerServing,
          onTap: () => onToggle(false),
        ),
        const SizedBox(width: 8),
        _ToggleOption(
          label: 'Per serving${servings != null ? ' (1/$servings)' : ''}',
          isSelected: showPerServing,
          onTap: () => onToggle(true),
        ),
      ],
    );
  }
}

/// A single toggle option button.
class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

/// Displays the four primary macronutrients in a row.
class _MacroRow extends StatelessWidget {
  const _MacroRow({required this.facts});

  final NutritionFacts facts;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _MacroItem(
            label: 'Calories',
            value: _formatValue(facts.calories),
            unit: 'kcal',
            color: Colors.red.shade400,
          ),
        ),
        Expanded(
          child: _MacroItem(
            label: 'Protein',
            value: _formatValue(facts.protein),
            unit: 'g',
            color: Colors.blue.shade400,
          ),
        ),
        Expanded(
          child: _MacroItem(
            label: 'Carbs',
            value: _formatValue(facts.carbs),
            unit: 'g',
            color: Colors.amber.shade600,
          ),
        ),
        Expanded(
          child: _MacroItem(
            label: 'Fat',
            value: _formatValue(facts.fat),
            unit: 'g',
            color: Colors.purple.shade400,
          ),
        ),
      ],
    );
  }

  /// Formats a nutrition value for display.
  String _formatValue(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }
}

/// Displays a single macro value with label and unit.
class _MacroItem extends StatelessWidget {
  const _MacroItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 11,
            color: color.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
