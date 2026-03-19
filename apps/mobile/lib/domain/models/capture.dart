/// Capture input types and extraction artifacts from SPEC §8.1.
///
/// These types represent the first two stages of the recipe capture pipeline:
/// 1. [CaptureInput] — the raw input from the user (link, image, speech, text).
/// 2. [ExtractionArtifact] — the raw extraction output from processing the input.
/// 3. [StructuredRecipeCandidate] — a structured recipe parsed from the artifact.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'ids.dart';
import 'recipe.dart';

part 'capture.freezed.dart';
part 'capture.g.dart';

/// The raw input provided by the user to capture a recipe.
///
/// Each variant represents a different capture modality.
/// Maps to SPEC §8.1 `CaptureInput`.
@freezed
sealed class CaptureInput with _$CaptureInput {
  /// A URL to a social media post or website containing a recipe.
  const factory CaptureInput.socialLink({
    /// The URL of the social media post or recipe page.
    required String url,
  }) = CaptureInputSocialLink;

  /// A screenshot of a recipe (e.g., from a social media app).
  const factory CaptureInput.screenshot({
    /// Reference to the uploaded screenshot image asset.
    required AssetId image,
  }) = CaptureInputScreenshot;

  /// A scanned physical recipe (e.g., from a cookbook or handwritten note).
  const factory CaptureInput.scan({
    /// Reference to the uploaded scan image asset.
    required AssetId image,
  }) = CaptureInputScan;

  /// A spoken recipe captured via speech-to-text.
  const factory CaptureInput.speech({
    /// The transcribed text from the speech input.
    required String transcript,
  }) = CaptureInputSpeech;

  /// A manually entered recipe in free-form text.
  const factory CaptureInput.manual({
    /// The raw text entered by the user.
    required String text,
  }) = CaptureInputManual;

  factory CaptureInput.fromJson(Map<String, dynamic> json) =>
      _$CaptureInputFromJson(json);
}

/// The result of running extraction on a [CaptureInput].
///
/// Contains all raw data extracted from the input before structuring.
/// Maps to SPEC §8.1 `ExtractionArtifact`.
@freezed
class ExtractionArtifact with _$ExtractionArtifact {
  const factory ExtractionArtifact({
    /// The capture input that produced this artifact.
    required CaptureId id,

    /// Version number for reprocessing support (starts at 1).
    required int version,

    /// Raw text extracted directly from the input.
    String? rawText,

    /// Text extracted via OCR from images.
    String? ocrText,

    /// Text from speech transcription.
    String? transcript,

    /// Individual ingredient text lines found in the source.
    required List<String> ingredients,

    /// Individual step text lines found in the source.
    required List<String> steps,

    /// References to images found in or associated with the source.
    required List<AssetId> images,

    /// Attribution and platform information about the source.
    required Source source,

    /// Confidence score for the extraction quality (0.0 to 1.0).
    required double confidence,
  }) = _ExtractionArtifact;

  factory ExtractionArtifact.fromJson(Map<String, dynamic> json) =>
      _$ExtractionArtifactFromJson(json);
}

/// A recipe candidate parsed and structured from an extraction artifact.
///
/// Maps to SPEC §8.1 `StructuredRecipeCandidate`.
@freezed
class StructuredRecipeCandidate with _$StructuredRecipeCandidate {
  const factory StructuredRecipeCandidate({
    /// The recipe title, if it could be identified.
    String? title,

    /// Raw ingredient lines as extracted (not yet parsed).
    required List<String> ingredientLines,

    /// Step-by-step instructions.
    required List<String> steps,

    /// Number of servings, if identified.
    int? servings,

    /// Total time in minutes, if identified.
    int? timeMinutes,

    /// Tags or categories associated with the recipe.
    required List<String> tags,

    /// Confidence score for the structuring quality (0.0 to 1.0).
    required double confidence,
  }) = _StructuredRecipeCandidate;

  factory StructuredRecipeCandidate.fromJson(Map<String, dynamic> json) =>
      _$StructuredRecipeCandidateFromJson(json);
}
