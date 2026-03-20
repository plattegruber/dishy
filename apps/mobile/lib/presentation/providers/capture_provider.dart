/// Riverpod provider for the recipe capture flow state.
///
/// Manages the lifecycle of submitting captures through three modalities:
/// - Manual text: synchronous (idle -> loading -> success/error)
/// - Social link: async (idle -> loading -> polling -> success/error)
/// - Screenshot: async (idle -> loading -> polling -> success/error)
library;

import 'dart:async';

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
  /// Creates the loading state with an optional message.
  const CaptureLoading({this.message = 'Processing...'});

  /// Progress message to display.
  final String message;
}

/// The async capture is being polled for completion.
final class CapturePolling extends CaptureState {
  /// Creates the polling state.
  const CapturePolling({required this.captureId, required this.status});

  /// The capture ID being polled.
  final String captureId;

  /// Current pipeline status.
  final String status;
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
/// Call [capture] for manual text, [captureSocialLink] for URLs,
/// or [captureScreenshot] for image captures.
class CaptureNotifier extends StateNotifier<CaptureState> {
  /// Creates the notifier with the given [repository].
  CaptureNotifier({required RecipeRepository repository})
      : _repository = repository,
        super(const CaptureIdle());

  final RecipeRepository _repository;
  Timer? _pollTimer;

  /// Submits raw text for recipe extraction (synchronous).
  ///
  /// Transitions through loading -> success/error states.
  /// Returns the captured recipe on success, or null on failure.
  Future<ResolvedRecipe?> capture(String text) async {
    state = const CaptureLoading(message: 'Extracting recipe...');

    try {
      final ResolvedRecipe recipe = await _repository.captureRecipe(text);
      state = CaptureSuccess(recipe: recipe);
      return recipe;
    } on Exception catch (e) {
      state = CaptureError(message: e.toString());
      return null;
    }
  }

  /// Submits a social link URL for async capture.
  ///
  /// Returns the capture ID for tracking, or null on failure.
  Future<String?> captureSocialLink(String url) async {
    state = const CaptureLoading(message: 'Submitting link...');

    try {
      final String captureId = await _repository.captureSocialLink(url);
      if (captureId.isEmpty) {
        state = const CaptureError(message: 'Failed to submit capture');
        return null;
      }
      state = CapturePolling(captureId: captureId, status: 'received');
      _startPolling(captureId);
      return captureId;
    } on Exception catch (e) {
      state = CaptureError(message: e.toString());
      return null;
    }
  }

  /// Submits a screenshot for async capture.
  ///
  /// Returns the capture ID for tracking, or null on failure.
  Future<String?> captureScreenshot({
    required String imageBase64,
    required String contentType,
  }) async {
    state = const CaptureLoading(message: 'Uploading image...');

    try {
      final String captureId = await _repository.captureScreenshot(
        imageBase64: imageBase64,
        contentType: contentType,
      );
      if (captureId.isEmpty) {
        state = const CaptureError(message: 'Failed to submit capture');
        return null;
      }
      state = CapturePolling(captureId: captureId, status: 'received');
      _startPolling(captureId);
      return captureId;
    } on Exception catch (e) {
      state = CaptureError(message: e.toString());
      return null;
    }
  }

  /// Starts polling for capture completion.
  void _startPolling(String captureId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _pollStatus(captureId),
    );
  }

  /// Polls the capture status once.
  Future<void> _pollStatus(String captureId) async {
    try {
      final CaptureStatusResult status =
          await _repository.getCaptureStatus(captureId);

      if (status.isResolved && status.recipeId != null) {
        _pollTimer?.cancel();
        // Fetch the resolved recipe
        final ResolvedRecipe recipe =
            await _repository.getRecipe(status.recipeId!);
        state = CaptureSuccess(recipe: recipe);
      } else if (status.isFailed) {
        _pollTimer?.cancel();
        state = CaptureError(
          message: status.errorMessage ?? 'Capture processing failed',
        );
      } else {
        state = CapturePolling(captureId: captureId, status: status.status);
      }
    } on Exception catch (e) {
      _pollTimer?.cancel();
      state = CaptureError(message: 'Polling failed: $e');
    }
  }

  /// Resets the state to idle and cancels any active polling.
  void reset() {
    _pollTimer?.cancel();
    state = const CaptureIdle();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

/// Provides the capture flow state.
///
/// Usage:
/// ```dart
/// final captureState = ref.watch(captureProvider);
/// final notifier = ref.read(captureProvider.notifier);
/// await notifier.capture('recipe text...');
/// await notifier.captureSocialLink('https://...');
/// ```
final StateNotifierProvider<CaptureNotifier, CaptureState> captureProvider =
    StateNotifierProvider<CaptureNotifier, CaptureState>(
  (Ref ref) {
    final RecipeRepository repository = ref.watch(recipeRepositoryProvider);
    return CaptureNotifier(repository: repository);
  },
);
