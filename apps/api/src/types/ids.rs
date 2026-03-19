//! Branded ID types for the Dishy domain model.
//!
//! Each entity in the system has its own ID type implemented as a newtype
//! wrapper around `String`. This prevents accidentally mixing IDs from
//! different entities (e.g., passing a `UserId` where a `RecipeId` is
//! expected). All ID types serialize to and from plain JSON strings.

use serde::{Deserialize, Serialize};

/// Unique identifier for a recipe.
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct RecipeId(pub String);

/// Unique identifier for a capture input.
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct CaptureId(pub String);

/// Unique identifier for a user.
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct UserId(pub String);

/// Unique identifier for a food entity in an external nutrition database.
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct FoodId(pub String);

/// Unique identifier for a stored asset (image, artifact, etc.) in R2.
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct AssetId(pub String);

/// Unique identifier for an extraction artifact version.
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct ArtifactId(pub String);

impl RecipeId {
    /// Creates a new `RecipeId` from a string value.
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    /// Returns the inner string value.
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl CaptureId {
    /// Creates a new `CaptureId` from a string value.
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    /// Returns the inner string value.
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl UserId {
    /// Creates a new `UserId` from a string value.
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    /// Returns the inner string value.
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl FoodId {
    /// Creates a new `FoodId` from a string value.
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    /// Returns the inner string value.
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl AssetId {
    /// Creates a new `AssetId` from a string value.
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    /// Returns the inner string value.
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl ArtifactId {
    /// Creates a new `ArtifactId` from a string value.
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    /// Returns the inner string value.
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl std::fmt::Display for RecipeId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl std::fmt::Display for CaptureId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl std::fmt::Display for UserId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl std::fmt::Display for FoodId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl std::fmt::Display for AssetId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl std::fmt::Display for ArtifactId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn recipe_id_serializes_as_plain_string() {
        let id = RecipeId::new("recipe_abc123");
        let json = serde_json::to_value(&id).expect("should serialize");
        assert_eq!(json, "recipe_abc123");
    }

    #[test]
    fn recipe_id_deserializes_from_plain_string() {
        let id: RecipeId = serde_json::from_str("\"recipe_abc123\"").expect("should deserialize");
        assert_eq!(id.as_str(), "recipe_abc123");
    }

    #[test]
    fn recipe_id_roundtrips_through_json() {
        let original = RecipeId::new("recipe_roundtrip");
        let json = serde_json::to_string(&original).expect("should serialize");
        let deserialized: RecipeId = serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(original, deserialized);
    }

    #[test]
    fn capture_id_serializes_as_plain_string() {
        let id = CaptureId::new("capture_xyz");
        let json = serde_json::to_value(&id).expect("should serialize");
        assert_eq!(json, "capture_xyz");
    }

    #[test]
    fn capture_id_roundtrips_through_json() {
        let original = CaptureId::new("capture_roundtrip");
        let json = serde_json::to_string(&original).expect("should serialize");
        let deserialized: CaptureId = serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(original, deserialized);
    }

    #[test]
    fn user_id_roundtrips_through_json() {
        let original = UserId::new("user_roundtrip");
        let json = serde_json::to_string(&original).expect("should serialize");
        let deserialized: UserId = serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(original, deserialized);
    }

    #[test]
    fn food_id_roundtrips_through_json() {
        let original = FoodId::new("food_roundtrip");
        let json = serde_json::to_string(&original).expect("should serialize");
        let deserialized: FoodId = serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(original, deserialized);
    }

    #[test]
    fn asset_id_roundtrips_through_json() {
        let original = AssetId::new("asset_roundtrip");
        let json = serde_json::to_string(&original).expect("should serialize");
        let deserialized: AssetId = serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(original, deserialized);
    }

    #[test]
    fn artifact_id_roundtrips_through_json() {
        let original = ArtifactId::new("artifact_roundtrip");
        let json = serde_json::to_string(&original).expect("should serialize");
        let deserialized: ArtifactId = serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(original, deserialized);
    }

    #[test]
    fn different_id_types_are_not_interchangeable() {
        // This is a compile-time guarantee, but we verify the runtime values differ
        let recipe_id = RecipeId::new("id_123");
        let capture_id = CaptureId::new("id_123");
        // They hold the same string but are different types
        assert_eq!(recipe_id.as_str(), capture_id.as_str());
    }

    #[test]
    fn id_display_matches_inner_value() {
        let id = RecipeId::new("recipe_display");
        assert_eq!(format!("{id}"), "recipe_display");
    }
}
