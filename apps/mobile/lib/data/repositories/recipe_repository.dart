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

  /// Submits a social link for async capture.
  ///
  /// Returns the capture ID for polling.
  Future<String> captureSocialLink(String url) async {
    final Map<String, Object?> json = await _apiClient.captureSocialLink(url);
    return json['capture_id'] as String? ?? '';
  }

  /// Submits a screenshot for async capture.
  ///
  /// Returns the capture ID for polling.
  Future<String> captureScreenshot({
    required String imageBase64,
    required String contentType,
  }) async {
    final Map<String, Object?> json = await _apiClient.captureScreenshot(
      imageBase64: imageBase64,
      contentType: contentType,
    );
    return json['capture_id'] as String? ?? '';
  }

  /// Polls the status of an async capture.
  ///
  /// Returns a map with `status`, `recipe_id`, and `error_message`.
  Future<CaptureStatusResult> getCaptureStatus(String captureId) async {
    final Map<String, Object?> json =
        await _apiClient.getCaptureStatus(captureId);
    return CaptureStatusResult(
      captureId: json['capture_id'] as String? ?? captureId,
      status: json['status'] as String? ?? 'unknown',
      recipeId: json['recipe_id'] as String?,
      errorMessage: json['error_message'] as String?,
    );
  }
}

/// Result of polling a capture status endpoint.
class CaptureStatusResult {
  /// Creates a capture status result.
  const CaptureStatusResult({
    required this.captureId,
    required this.status,
    this.recipeId,
    this.errorMessage,
  });

  /// The capture ID.
  final String captureId;

  /// The pipeline state: received, processing, extracted, resolved, failed.
  final String status;

  /// The produced recipe ID, if resolved.
  final String? recipeId;

  /// The error message, if failed.
  final String? errorMessage;

  /// Whether the capture is still in progress.
  bool get isProcessing =>
      status == 'received' || status == 'processing' || status == 'extracted';

  /// Whether the capture completed successfully.
  bool get isResolved => status == 'resolved';

  /// Whether the capture failed.
  bool get isFailed => status == 'failed';
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
