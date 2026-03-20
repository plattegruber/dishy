/// Riverpod provider for the recipe capture flow state.
///
/// Manages the lifecycle of submitting raw text for extraction:
/// idle -> loading -> success/error.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/recipe_repository.dart';
import '../../domain/models/recipe.dart';

/// State for the capture flow.
///
/// Sealed class hierarchy allows exhaustive pattern matching in the UI.
sealed class CaptureState {
  /// Creates the base capture state.
  const CaptureState();
}

/// The capture form is idle and ready for input.
final class CaptureIdle extends CaptureState {
  /// Creates the idle state.
  const CaptureIdle();
}

/// The capture is in progress (API call running).
final class CaptureLoading extends CaptureState {
  /// Creates the loading state.
  const CaptureLoading();
}

/// The capture completed successfully.
final class CaptureSuccess extends CaptureState {
  /// Creates the success state with the captured recipe.
  const CaptureSuccess({required this.recipe});

  /// The captured and structured recipe.
  final ResolvedRecipe recipe;
}

/// The capture failed with an error.
final class CaptureError extends CaptureState {
  /// Creates the error state with a message.
  const CaptureError({required this.message});

  /// Human-readable error description.
  final String message;
}

/// Notifier that manages the capture flow state.
///
/// Call [capture] with raw text to start the extraction pipeline.
class CaptureNotifier extends StateNotifier<CaptureState> {
  /// Creates the notifier with the given [repository].
  CaptureNotifier({required RecipeRepository repository})
      : _repository = repository,
        super(const CaptureIdle());

  final RecipeRepository _repository;

  /// Submits raw text for recipe extraction.
  ///
  /// Transitions through loading -> success/error states.
  /// Returns the captured recipe on success, or null on failure.
  Future<ResolvedRecipe?> capture(String text) async {
    state = const CaptureLoading();

    try {
      final ResolvedRecipe recipe = await _repository.captureRecipe(text);
      state = CaptureSuccess(recipe: recipe);
      return recipe;
    } on Exception catch (e) {
      state = CaptureError(message: e.toString());
      return null;
    }
  }

  /// Resets the state to idle.
  void reset() {
    state = const CaptureIdle();
  }
}

/// Provides the capture flow state.
///
/// Usage:
/// ```dart
/// final captureState = ref.watch(captureProvider);
/// final notifier = ref.read(captureProvider.notifier);
/// await notifier.capture('recipe text...');
/// ```
final StateNotifierProvider<CaptureNotifier, CaptureState> captureProvider =
    StateNotifierProvider<CaptureNotifier, CaptureState>(
  (Ref ref) {
    final RecipeRepository repository = ref.watch(recipeRepositoryProvider);
    return CaptureNotifier(repository: repository);
  },
);
