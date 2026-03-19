/// Branded ID types for the Dishy domain model.
///
/// Each typedef wraps a [String] to provide semantic clarity at call sites.
/// While Dart typedefs don't enforce type safety at compile time, they
/// serve as documentation and make code more readable.
library;

/// Unique identifier for a recipe.
typedef RecipeId = String;

/// Unique identifier for a capture input.
typedef CaptureId = String;

/// Unique identifier for a user.
typedef UserId = String;

/// Unique identifier for a food entity in an external nutrition database.
typedef FoodId = String;

/// Unique identifier for a stored asset (image, artifact, etc.) in R2.
typedef AssetId = String;

/// Unique identifier for an extraction artifact version.
typedef ArtifactId = String;
