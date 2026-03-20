/// Repository for recipe CRUD operations.
///
/// Wraps the [ApiClient] to provide typed recipe operations using the
/// domain model types. Handles JSON deserialization and error mapping.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/correlation_provider.dart';
import '../../domain/models/recipe.dart';
import '../datasources/api_client.dart';

/// Provides typed access to recipe data from the Dishy API.
///
/// Converts raw JSON maps from [ApiClient] into domain model objects
/// using freezed-generated fromJson factories.
class RecipeRepository {
  /// Creates a [RecipeRepository] backed by the given [apiClient].
  const RecipeRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Captures a recipe from raw text.
  ///
  /// Sends the text to the API for Claude extraction and returns
  /// the structured [ResolvedRecipe].
  ///
  /// Throws if the API call fails or the response is malformed.
  Future<ResolvedRecipe> captureRecipe(String text) async {
    final Map<String, Object?> json = await _apiClient.captureRecipe(text);
    return ResolvedRecipe.fromJson(json.cast<String, dynamic>());
  }

  /// Fetches all recipes for the authenticated user.
  ///
  /// Returns an empty list if the user has no saved recipes.
  Future<List<ResolvedRecipe>> getRecipes() async {
    final List<Map<String, Object?>> jsonList = await _apiClient.getRecipes();
    return jsonList
        .map(
          (Map<String, Object?> json) =>
              ResolvedRecipe.fromJson(json.cast<String, dynamic>()),
        )
        .toList();
  }

  /// Fetches a single recipe by its ID.
  ///
  /// Throws if the recipe is not found (404) or the request fails.
  Future<ResolvedRecipe> getRecipe(String id) async {
    final Map<String, Object?> json = await _apiClient.getRecipe(id);
    return ResolvedRecipe.fromJson(json.cast<String, dynamic>());
  }

  /// Captures a recipe from a social media URL (async pipeline).
  ///
  /// Returns the capture ID for status polling.
  /// Throws if the API call fails.
  Future<String> captureSocialLink(String url) async {
    final Map<String, Object?> json = await _apiClient.captureSocialLink(url);
    final String captureId = json['capture_id'] as String? ?? '';
    if (captureId.isEmpty) {
      throw Exception('No capture_id in response');
    }
    return captureId;
  }

  /// Captures a recipe from a screenshot (async pipeline).
  ///
  /// Returns the capture ID for status polling.
  /// Throws if the API call fails.
  Future<String> captureScreenshot(String base64ImageData) async {
    final Map<String, Object?> json =
        await _apiClient.captureScreenshot(base64ImageData);
    final String captureId = json['capture_id'] as String? ?? '';
    if (captureId.isEmpty) {
      throw Exception('No capture_id in response');
    }
    return captureId;
  }

  /// Polls the status of an async capture.
  ///
  /// Returns the capture status including pipeline state, optional
  /// recipe ID, and optional error message.
  Future<CaptureStatusResult> getCaptureStatus(String captureId) async {
    final Map<String, Object?> json =
        await _apiClient.getCaptureStatus(captureId);
    return CaptureStatusResult(
      captureId: json['capture_id'] as String? ?? captureId,
      pipelineState: json['pipeline_state'] as String? ?? 'unknown',
      recipeId: json['recipe_id'] as String?,
      errorMessage: json['error_message'] as String?,
    );
  }
}

/// Result of polling a capture's pipeline status.
class CaptureStatusResult {
  /// Creates a [CaptureStatusResult].
  const CaptureStatusResult({
    required this.captureId,
    required this.pipelineState,
    this.recipeId,
    this.errorMessage,
  });

  /// The capture ID.
  final String captureId;

  /// Current pipeline state (received, processing, extracted, resolved, failed).
  final String pipelineState;

  /// The recipe ID, available once the capture is resolved.
  final String? recipeId;

  /// Error message if the capture failed.
  final String? errorMessage;

  /// Whether the capture has finished (resolved or failed).
  bool get isTerminal =>
      pipelineState == 'resolved' || pipelineState == 'failed';

  /// Whether the capture completed successfully.
  bool get isResolved => pipelineState == 'resolved';

  /// Whether the capture failed.
  bool get isFailed => pipelineState == 'failed';
}

/// Provides the [RecipeRepository] instance.
///
/// Depends on [apiClientProvider] for the underlying HTTP client.
final Provider<RecipeRepository> recipeRepositoryProvider =
    Provider<RecipeRepository>(
  (Ref ref) {
    final ApiClient apiClient = ref.watch(apiClientProvider);
    return RecipeRepository(apiClient: apiClient);
  },
);

/// Provides the [ApiClient] instance.
///
/// Creates a new [ApiClient] pre-configured with logging and auth.
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>(
  (Ref ref) {
    final logService = ref.watch(logServiceProvider);
    return ApiClient(logService: logService);
  },
);
