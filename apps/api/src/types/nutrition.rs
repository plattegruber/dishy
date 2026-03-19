//! Nutrition types from SPEC §8.3.
//!
//! Nutrition data is computed from resolved ingredients and attached to
//! recipes. The system tracks both per-recipe and per-serving nutrition
//! facts, along with a status indicating the quality of the computation.

use serde::{Deserialize, Serialize};

/// Core nutritional facts for a recipe or serving.
///
/// Contains the four primary macronutrient values. All values are in
/// grams except calories (kcal).
///
/// Maps to SPEC §8.3 `NutritionFacts`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NutritionFacts {
    /// Total calories in kilocalories (kcal).
    pub calories: f64,
    /// Protein content in grams.
    pub protein: f64,
    /// Carbohydrate content in grams.
    pub carbs: f64,
    /// Fat content in grams.
    pub fat: f64,
}

/// The full nutrition computation result for a recipe.
///
/// Contains per-recipe totals, optional per-serving values (when the
/// recipe has a known serving count), and a status indicating how
/// reliable the computation is.
///
/// Maps to SPEC §8.3 `NutritionComputation`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NutritionComputation {
    /// Total nutrition for the entire recipe.
    pub per_recipe: NutritionFacts,
    /// Nutrition per serving, if the recipe has a defined serving count.
    pub per_serving: Option<NutritionFacts>,
    /// Status indicating the reliability of this computation.
    pub status: NutritionStatus,
}

/// Status of a nutrition computation, indicating data quality.
///
/// Maps to SPEC §10 `NutritionState`. The status tracks how the
/// nutrition values were determined:
///
/// - `Pending` — computation has not been attempted yet.
/// - `Calculated` — all ingredients were matched and values are precise.
/// - `Estimated` — some ingredients used fuzzy matches or estimates.
/// - `Unavailable` — nutrition could not be computed.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum NutritionStatus {
    /// Nutrition computation has not been attempted yet.
    Pending,
    /// All ingredients matched exactly — nutrition values are precise.
    Calculated,
    /// Some ingredients used fuzzy matches — nutrition values are estimated.
    Estimated,
    /// Nutrition could not be computed (too many unmatched ingredients).
    Unavailable,
}

impl NutritionStatus {
    /// Returns true if this status represents a terminal state
    /// (i.e., the computation has been attempted).
    pub fn is_terminal(&self) -> bool {
        matches!(
            self,
            NutritionStatus::Calculated | NutritionStatus::Estimated | NutritionStatus::Unavailable
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn nutrition_facts_roundtrips() {
        let facts = NutritionFacts {
            calories: 350.5,
            protein: 12.3,
            carbs: 45.0,
            fat: 15.2,
        };
        let json = serde_json::to_string(&facts).expect("should serialize");
        let deserialized: NutritionFacts = serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(deserialized.calories, 350.5);
        assert_eq!(deserialized.protein, 12.3);
        assert_eq!(deserialized.carbs, 45.0);
        assert_eq!(deserialized.fat, 15.2);
    }

    #[test]
    fn nutrition_computation_with_per_serving_roundtrips() {
        let computation = NutritionComputation {
            per_recipe: NutritionFacts {
                calories: 2800.0,
                protein: 80.0,
                carbs: 320.0,
                fat: 120.0,
            },
            per_serving: Some(NutritionFacts {
                calories: 350.0,
                protein: 10.0,
                carbs: 40.0,
                fat: 15.0,
            }),
            status: NutritionStatus::Calculated,
        };
        let json = serde_json::to_string(&computation).expect("should serialize");
        let deserialized: NutritionComputation =
            serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(deserialized.per_recipe.calories, 2800.0);
        assert!(deserialized.per_serving.is_some());
        assert_eq!(deserialized.status, NutritionStatus::Calculated);
    }

    #[test]
    fn nutrition_computation_without_per_serving_roundtrips() {
        let computation = NutritionComputation {
            per_recipe: NutritionFacts {
                calories: 500.0,
                protein: 20.0,
                carbs: 60.0,
                fat: 10.0,
            },
            per_serving: None,
            status: NutritionStatus::Estimated,
        };
        let json = serde_json::to_string(&computation).expect("should serialize");
        let deserialized: NutritionComputation =
            serde_json::from_str(&json).expect("should deserialize");
        assert!(deserialized.per_serving.is_none());
        assert_eq!(deserialized.status, NutritionStatus::Estimated);
    }

    #[test]
    fn nutrition_status_pending_serializes() {
        let status = NutritionStatus::Pending;
        let json = serde_json::to_value(&status).expect("should serialize");
        assert_eq!(json, "pending");
    }

    #[test]
    fn nutrition_status_calculated_serializes() {
        let status = NutritionStatus::Calculated;
        let json = serde_json::to_value(&status).expect("should serialize");
        assert_eq!(json, "calculated");
    }

    #[test]
    fn nutrition_status_estimated_serializes() {
        let status = NutritionStatus::Estimated;
        let json = serde_json::to_value(&status).expect("should serialize");
        assert_eq!(json, "estimated");
    }

    #[test]
    fn nutrition_status_unavailable_serializes() {
        let status = NutritionStatus::Unavailable;
        let json = serde_json::to_value(&status).expect("should serialize");
        assert_eq!(json, "unavailable");
    }

    #[test]
    fn nutrition_status_roundtrips_all_variants() {
        for status in &[
            NutritionStatus::Pending,
            NutritionStatus::Calculated,
            NutritionStatus::Estimated,
            NutritionStatus::Unavailable,
        ] {
            let json = serde_json::to_string(status).expect("should serialize");
            let deserialized: NutritionStatus =
                serde_json::from_str(&json).expect("should deserialize");
            assert_eq!(&deserialized, status);
        }
    }

    #[test]
    fn nutrition_status_is_terminal() {
        assert!(!NutritionStatus::Pending.is_terminal());
        assert!(NutritionStatus::Calculated.is_terminal());
        assert!(NutritionStatus::Estimated.is_terminal());
        assert!(NutritionStatus::Unavailable.is_terminal());
    }
}
