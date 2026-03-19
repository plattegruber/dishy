//! Ingredient types from SPEC §8.2.
//!
//! The ingredient pipeline takes raw text lines from a recipe and transforms
//! them through three stages:
//!
//! 1. **IngredientLine** — raw text with an optional parse result.
//! 2. **ParsedIngredient** — structured fields (quantity, unit, name, preparation).
//! 3. **ResolvedIngredient** — a parsed ingredient matched against a food database.

use serde::{Deserialize, Serialize};

use super::ids::FoodId;

/// A single ingredient line from a recipe, with its parse result.
///
/// The `raw_text` is always preserved. The `parsed` field is `None` if
/// parsing failed, or contains the structured ingredient data if parsing
/// succeeded.
///
/// Maps to SPEC §8.2 `IngredientLine`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IngredientLine {
    /// The original ingredient text as it appeared in the recipe.
    pub raw_text: String,
    /// The structured parse result, if parsing succeeded.
    pub parsed: Option<ParsedIngredient>,
}

/// A structured ingredient parsed from free-form text.
///
/// Each field is optional because natural language ingredient lines
/// vary widely — "a pinch of salt" has no numeric quantity or unit,
/// while "2 cups all-purpose flour, sifted" has all four fields.
///
/// Maps to SPEC §8.2 `ParsedIngredient`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParsedIngredient {
    /// Numeric quantity (e.g., 2.0, 0.5). `None` if not specified.
    pub quantity: Option<f64>,
    /// Unit of measurement (e.g., "cup", "tbsp", "g"). `None` if unitless.
    pub unit: Option<String>,
    /// The ingredient name (e.g., "all-purpose flour", "salt").
    pub name: String,
    /// Preparation instructions (e.g., "diced", "sifted", "room temperature").
    pub preparation: Option<String>,
}

/// An ingredient that has been parsed and resolved against a food database.
///
/// Combines the structured parse with a resolution status indicating
/// whether the ingredient was matched to a known food entity.
///
/// Maps to SPEC §8.2 `ResolvedIngredient`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResolvedIngredient {
    /// The parsed ingredient data.
    pub parsed: ParsedIngredient,
    /// The resolution result from the food database lookup.
    pub resolution: IngredientResolution,
}

/// The result of trying to match a parsed ingredient to a known food entity.
///
/// Maps to SPEC §8.2 `IngredientResolution`.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum IngredientResolution {
    /// Exact match found in the food database.
    Matched {
        /// The ID of the matched food entity.
        food_id: FoodId,
        /// Confidence score for the match (0.0 to 1.0).
        confidence: f64,
    },
    /// Approximate match found — multiple candidates with varying confidence.
    FuzzyMatched {
        /// Candidate food entity IDs with their confidence scores.
        candidates: Vec<FuzzyCandidate>,
        /// Overall confidence in the best match (0.0 to 1.0).
        confidence: f64,
    },
    /// No match found in the food database.
    Unmatched {
        /// The original text that could not be matched.
        text: String,
    },
}

/// A single candidate from a fuzzy ingredient match.
///
/// Represents one possible food entity that the ingredient text
/// might refer to, along with a confidence score.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FuzzyCandidate {
    /// The ID of the candidate food entity.
    pub food_id: FoodId,
    /// Confidence score for this candidate (0.0 to 1.0).
    pub confidence: f64,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ingredient_line_with_parsed_roundtrips() {
        let line = IngredientLine {
            raw_text: "2 cups all-purpose flour, sifted".to_string(),
            parsed: Some(ParsedIngredient {
                quantity: Some(2.0),
                unit: Some("cups".to_string()),
                name: "all-purpose flour".to_string(),
                preparation: Some("sifted".to_string()),
            }),
        };
        let json = serde_json::to_string(&line).expect("should serialize");
        let deserialized: IngredientLine = serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(deserialized.raw_text, "2 cups all-purpose flour, sifted");
        let parsed = deserialized.parsed.expect("should have parsed");
        assert_eq!(parsed.quantity, Some(2.0));
        assert_eq!(parsed.unit.as_deref(), Some("cups"));
        assert_eq!(parsed.name, "all-purpose flour");
        assert_eq!(parsed.preparation.as_deref(), Some("sifted"));
    }

    #[test]
    fn ingredient_line_without_parsed_roundtrips() {
        let line = IngredientLine {
            raw_text: "a pinch of salt".to_string(),
            parsed: None,
        };
        let json = serde_json::to_string(&line).expect("should serialize");
        let deserialized: IngredientLine = serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(deserialized.raw_text, "a pinch of salt");
        assert!(deserialized.parsed.is_none());
    }

    #[test]
    fn parsed_ingredient_minimal_roundtrips() {
        let parsed = ParsedIngredient {
            quantity: None,
            unit: None,
            name: "salt".to_string(),
            preparation: None,
        };
        let json = serde_json::to_string(&parsed).expect("should serialize");
        let deserialized: ParsedIngredient =
            serde_json::from_str(&json).expect("should deserialize");
        assert!(deserialized.quantity.is_none());
        assert!(deserialized.unit.is_none());
        assert_eq!(deserialized.name, "salt");
        assert!(deserialized.preparation.is_none());
    }

    #[test]
    fn ingredient_resolution_matched_roundtrips() {
        let resolution = IngredientResolution::Matched {
            food_id: FoodId::new("usda_12345"),
            confidence: 0.95,
        };
        let json = serde_json::to_string(&resolution).expect("should serialize");
        let deserialized: IngredientResolution =
            serde_json::from_str(&json).expect("should deserialize");
        match deserialized {
            IngredientResolution::Matched {
                food_id,
                confidence,
            } => {
                assert_eq!(food_id.as_str(), "usda_12345");
                assert_eq!(confidence, 0.95);
            }
            _ => panic!("expected Matched variant"),
        }
    }

    #[test]
    fn ingredient_resolution_fuzzy_matched_roundtrips() {
        let resolution = IngredientResolution::FuzzyMatched {
            candidates: vec![
                FuzzyCandidate {
                    food_id: FoodId::new("usda_111"),
                    confidence: 0.8,
                },
                FuzzyCandidate {
                    food_id: FoodId::new("usda_222"),
                    confidence: 0.6,
                },
            ],
            confidence: 0.8,
        };
        let json = serde_json::to_string(&resolution).expect("should serialize");
        let deserialized: IngredientResolution =
            serde_json::from_str(&json).expect("should deserialize");
        match deserialized {
            IngredientResolution::FuzzyMatched {
                candidates,
                confidence,
            } => {
                assert_eq!(candidates.len(), 2);
                assert_eq!(confidence, 0.8);
            }
            _ => panic!("expected FuzzyMatched variant"),
        }
    }

    #[test]
    fn ingredient_resolution_unmatched_roundtrips() {
        let resolution = IngredientResolution::Unmatched {
            text: "secret spice mix".to_string(),
        };
        let json = serde_json::to_string(&resolution).expect("should serialize");
        let deserialized: IngredientResolution =
            serde_json::from_str(&json).expect("should deserialize");
        match deserialized {
            IngredientResolution::Unmatched { text } => {
                assert_eq!(text, "secret spice mix");
            }
            _ => panic!("expected Unmatched variant"),
        }
    }

    #[test]
    fn ingredient_resolution_serializes_with_type_tag() {
        let resolution = IngredientResolution::Matched {
            food_id: FoodId::new("usda_001"),
            confidence: 0.99,
        };
        let json = serde_json::to_value(&resolution).expect("should serialize");
        assert_eq!(json["type"], "matched");
    }

    #[test]
    fn resolved_ingredient_roundtrips() {
        let resolved = ResolvedIngredient {
            parsed: ParsedIngredient {
                quantity: Some(1.0),
                unit: Some("cup".to_string()),
                name: "sugar".to_string(),
                preparation: None,
            },
            resolution: IngredientResolution::Matched {
                food_id: FoodId::new("usda_sugar"),
                confidence: 0.97,
            },
        };
        let json = serde_json::to_string(&resolved).expect("should serialize");
        let deserialized: ResolvedIngredient =
            serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(deserialized.parsed.name, "sugar");
        match deserialized.resolution {
            IngredientResolution::Matched { food_id, .. } => {
                assert_eq!(food_id.as_str(), "usda_sugar");
            }
            _ => panic!("expected Matched variant"),
        }
    }
}
