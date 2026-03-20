/// Capture screen for pasting or typing recipe text.
///
/// Provides a large text area for the user to enter raw recipe text
/// and a submit button to run the extraction pipeline. Shows loading
/// state during extraction and navigates to the recipe detail on success.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/recipe.dart';
import '../providers/capture_provider.dart';
import '../providers/recipe_list_provider.dart';

/// Screen for capturing a recipe from raw text.
///
/// The user pastes or types recipe text into a large text field, then
/// taps "Save Recipe" to run the Claude extraction pipeline. On success,
/// navigates to the recipe detail view.
class CaptureScreen extends ConsumerStatefulWidget {
  /// Creates the capture screen.
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final String text = _textController.text.trim();
    if (text.isEmpty) {
      return;
    }

    final CaptureNotifier notifier = ref.read(captureProvider.notifier);
    final ResolvedRecipe? recipe = await notifier.capture(text);

    if (recipe != null && mounted) {
      // Add to the recipe list immediately
      ref.read(recipeListProvider.notifier).addRecipe(recipe);
      // Navigate to the recipe detail
      context.go('/recipes/${recipe.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final CaptureState captureState = ref.watch(captureProvider);
    final bool isLoading = captureState is CaptureLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Recipe'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Paste or type your recipe below',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    hintText:
                        'e.g. Chocolate Cake\n\nIngredients:\n2 cups flour\n1 cup sugar\n...\n\nInstructions:\n1. Preheat oven to 350F\n2. Mix dry ingredients\n...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (captureState case CaptureError(:final String message))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              FilledButton.icon(
                onPressed: isLoading ? null : _handleSubmit,
                icon: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_fix_high),
                label: Text(isLoading ? 'Extracting...' : 'Save Recipe'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
