/// Riverpod provider for the recipe capture flow state.
///
/// Manages the lifecycle of submitting raw text, social links, or
/// screenshots for extraction:
/// idle -> loading -> success/error (sync)
/// idle -> loading -> polling -> success/error (async)
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
  /// Creates the loading state with an optional description.
  const CaptureLoading({this.description = 'Processing...'});

  /// Human-readable description of what's happening.
  final String description;
}

/// The capture is queued and being processed asynchronously.
final class CapturePolling extends CaptureState {
  /// Creates the polling state with the capture ID and current pipeline state.
  const CapturePolling({
    required this.captureId,
    required this.pipelineState,
  });

  /// The capture ID being polled.
  final String captureId;

  /// The current pipeline state.
  final String pipelineState;
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
/// Supports three capture modes:
/// - [capture] for manual text (synchronous).
/// - [captureSocialLink] for social URLs (async with polling).
/// - [captureScreenshot] for screenshot images (async with polling).
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
    state = const CaptureLoading(description: 'Extracting recipe...');

    try {
      final ResolvedRecipe recipe = await _repository.captureRecipe(text);
      state = CaptureSuccess(recipe: recipe);
      return recipe;
    } on Exception catch (e) {
      state = CaptureError(message: e.toString());
      return null;
    }
  }

  /// Submits a social media URL for async capture.
  ///
  /// Returns the capture ID for the caller to track, or null on failure.
  /// The state transitions: loading -> polling -> success/error.
  Future<String?> captureSocialLink(String url) async {
    state = const CaptureLoading(description: 'Queueing social link...');

    try {
      final String captureId = await _repository.captureSocialLink(url);
      state = CapturePolling(
        captureId: captureId,
        pipelineState: 'received',
      );
      _startPolling(captureId);
      return captureId;
    } on Exception catch (e) {
      state = CaptureError(message: e.toString());
      return null;
    }
  }

  /// Submits a screenshot for async capture.
  ///
  /// Returns the capture ID for the caller to track, or null on failure.
  /// The state transitions: loading -> polling -> success/error.
  Future<String?> captureScreenshot(String base64ImageData) async {
    state = const CaptureLoading(description: 'Queueing screenshot...');

    try {
      final String captureId =
          await _repository.captureScreenshot(base64ImageData);
      state = CapturePolling(
        captureId: captureId,
        pipelineState: 'received',
      );
      _startPolling(captureId);
      return captureId;
    } on Exception catch (e) {
      state = CaptureError(message: e.toString());
      return null;
    }
  }

  /// Starts periodic polling for a capture's status.
  void _startPolling(String captureId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pollStatus(captureId),
    );
  }

  /// Polls the capture status once. Stops polling on terminal states.
  Future<void> _pollStatus(String captureId) async {
    try {
      final CaptureStatusResult status =
          await _repository.getCaptureStatus(captureId);

      if (status.isResolved && status.recipeId != null) {
        _pollTimer?.cancel();
        // Fetch the full recipe
        try {
          final ResolvedRecipe recipe =
              await _repository.getRecipe(status.recipeId!);
          state = CaptureSuccess(recipe: recipe);
        } on Exception catch (e) {
          state = CaptureError(
            message: 'Recipe saved but failed to load: $e',
          );
        }
      } else if (status.isFailed) {
        _pollTimer?.cancel();
        state = CaptureError(
          message: status.errorMessage ?? 'Capture processing failed',
        );
      } else {
        // Still processing -- update the polling state
        state = CapturePolling(
          captureId: captureId,
          pipelineState: status.pipelineState,
        );
      }
    } on Exception {
      // Network error during polling -- don't stop, just log
      // The timer will retry on the next tick
      state = CapturePolling(
        captureId: captureId,
        pipelineState: 'polling_error',
      );
    }
  }

  /// Resets the state to idle and cancels any polling.
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
/// await notifier.captureSocialLink('https://instagram.com/p/abc');
/// ```
final StateNotifierProvider<CaptureNotifier, CaptureState> captureProvider =
    StateNotifierProvider<CaptureNotifier, CaptureState>(
  (Ref ref) {
    final RecipeRepository repository = ref.watch(recipeRepositoryProvider);
    return CaptureNotifier(repository: repository);
  },
);
