//! Typed query functions for D1 database operations.
//!
//! Each function takes a D1 database reference and domain types, executing
//! parameterised SQL queries. Results are deserialized into domain structs
//! via serde.
//!
//! These functions are designed to be called from route handlers after
//! obtaining the D1 binding from the Worker environment:
//!
//! ```rust,ignore
//! let db = ctx.env.d1("DB")?;
//! let recipe = queries::get_recipe(&db, &recipe_id).await?;
//! ```
//!
//! **Note:** D1 query execution requires the `wasm32-unknown-unknown`
//! target (Cloudflare Workers runtime). These functions cannot be
//! unit-tested outside of the Workers environment. Integration tests
//! should use `wrangler dev --test` or Miniflare.

// Imports are cfg-gated because the query functions are only compiled on wasm32.
// On non-wasm targets, a const block ensures the types are referenced to catch
// breakage early.
#[cfg(target_arch = "wasm32")]
use crate::types::capture::{CaptureInput, ExtractionArtifact};
#[cfg(target_arch = "wasm32")]
use crate::types::ids::{CaptureId, UserId};
#[cfg(target_arch = "wasm32")]
use crate::types::recipe::{ResolvedRecipe, UserRecipeView};

/// Errors that can occur during database operations.
#[derive(Debug, thiserror::Error)]
pub enum DbError {
    /// A database query failed.
    #[error("query failed: {0}")]
    QueryFailed(String),

    /// JSON serialization/deserialization failed for a column value.
    #[error("serialization error: {0}")]
    SerializationError(String),

    /// The requested entity was not found.
    #[error("not found: {entity} with id {id}")]
    NotFound {
        /// The type of entity that was not found.
        entity: String,
        /// The ID that was looked up.
        id: String,
    },
}

/// Inserts a new capture input into the database.
///
/// # Arguments
///
/// * `db` — D1 database binding.
/// * `id` — The capture ID.
/// * `user_id` — The user who created the capture.
/// * `input` — The capture input data.
///
/// # Errors
///
/// Returns `DbError::QueryFailed` if the insert fails, or
/// `DbError::SerializationError` if the input cannot be serialized.
#[cfg(target_arch = "wasm32")]
pub async fn insert_capture_input(
    db: &worker::d1::D1Database,
    id: &CaptureId,
    user_id: &UserId,
    input: &CaptureInput,
) -> Result<(), DbError> {
    use worker::wasm_bindgen::JsValue;

    let input_type = match input {
        CaptureInput::SocialLink { .. } => "social_link",
        CaptureInput::Screenshot { .. } => "screenshot",
        CaptureInput::Scan { .. } => "scan",
        CaptureInput::Speech { .. } => "speech",
        CaptureInput::Manual { .. } => "manual",
    };

    let input_data =
        serde_json::to_string(input).map_err(|e| DbError::SerializationError(e.to_string()))?;

    let now = chrono::Utc::now().to_rfc3339();

    let statement = db.prepare(
        "INSERT INTO capture_inputs (id, user_id, input_type, input_data, pipeline_state, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, 'received', ?5, ?6)"
    );

    statement
        .bind(&[
            JsValue::from_str(id.as_str()),
            JsValue::from_str(user_id.as_str()),
            JsValue::from_str(input_type),
            JsValue::from_str(&input_data),
            JsValue::from_str(&now),
            JsValue::from_str(&now),
        ])
        .map_err(|e| DbError::QueryFailed(format!("bind failed: {e}")))?
        .run()
        .await
        .map_err(|e| DbError::QueryFailed(format!("run failed: {e}")))?;

    Ok(())
}

/// Inserts a new extraction artifact into the database.
///
/// # Arguments
///
/// * `db` — D1 database binding.
/// * `artifact_id` — Unique ID for this artifact.
/// * `artifact` — The extraction artifact data.
///
/// # Errors
///
/// Returns `DbError` on query or serialization failure.
#[cfg(target_arch = "wasm32")]
pub async fn insert_extraction_artifact(
    db: &worker::d1::D1Database,
    artifact_id: &str,
    artifact: &ExtractionArtifact,
) -> Result<(), DbError> {
    use worker::wasm_bindgen::JsValue;

    let ingredients_json = serde_json::to_string(&artifact.ingredients)
        .map_err(|e| DbError::SerializationError(e.to_string()))?;
    let steps_json = serde_json::to_string(&artifact.steps)
        .map_err(|e| DbError::SerializationError(e.to_string()))?;
    let images_json = serde_json::to_string(&artifact.images)
        .map_err(|e| DbError::SerializationError(e.to_string()))?;
    let source_json = serde_json::to_string(&artifact.source)
        .map_err(|e| DbError::SerializationError(e.to_string()))?;

    let now = chrono::Utc::now().to_rfc3339();

    let statement = db.prepare(
        "INSERT INTO extraction_artifacts (id, capture_id, version, raw_text, ocr_text, transcript, ingredients_json, steps_json, images_json, source_json, confidence, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12)"
    );

    let raw_text_val = match &artifact.raw_text {
        Some(t) => JsValue::from_str(t),
        None => JsValue::null(),
    };
    let ocr_text_val = match &artifact.ocr_text {
        Some(t) => JsValue::from_str(t),
        None => JsValue::null(),
    };
    let transcript_val = match &artifact.transcript {
        Some(t) => JsValue::from_str(t),
        None => JsValue::null(),
    };

    statement
        .bind(&[
            JsValue::from_str(artifact_id),
            JsValue::from_str(artifact.id.as_str()),
            JsValue::from_f64(f64::from(artifact.version)),
            raw_text_val,
            ocr_text_val,
            transcript_val,
            JsValue::from_str(&ingredients_json),
            JsValue::from_str(&steps_json),
            JsValue::from_str(&images_json),
            JsValue::from_str(&source_json),
            JsValue::from_f64(artifact.confidence),
            JsValue::from_str(&now),
        ])
        .map_err(|e| DbError::QueryFailed(format!("bind failed: {e}")))?
        .run()
        .await
        .map_err(|e| DbError::QueryFailed(format!("run failed: {e}")))?;

    Ok(())
}

/// Inserts a resolved recipe with its ingredients and steps.
///
/// This is a multi-statement operation that inserts the recipe row,
/// all ingredient rows, and all step rows.
///
/// # Arguments
///
/// * `db` — D1 database binding.
/// * `recipe` — The fully resolved recipe to persist.
///
/// # Errors
///
/// Returns `DbError` on query or serialization failure.
#[cfg(target_arch = "wasm32")]
pub async fn insert_recipe(
    db: &worker::d1::D1Database,
    recipe: &ResolvedRecipe,
) -> Result<(), DbError> {
    use worker::wasm_bindgen::JsValue;

    let source_json = serde_json::to_string(&recipe.source)
        .map_err(|e| DbError::SerializationError(e.to_string()))?;
    let nutrition_json = serde_json::to_string(&recipe.nutrition)
        .map_err(|e| DbError::SerializationError(e.to_string()))?;
    let cover_json = serde_json::to_string(&recipe.cover)
        .map_err(|e| DbError::SerializationError(e.to_string()))?;
    let tags_json = serde_json::to_string(&recipe.tags)
        .map_err(|e| DbError::SerializationError(e.to_string()))?;

    let now = chrono::Utc::now().to_rfc3339();

    let servings_val = match recipe.servings {
        Some(s) => JsValue::from_f64(f64::from(s)),
        None => JsValue::null(),
    };
    let time_val = match recipe.time_minutes {
        Some(t) => JsValue::from_f64(f64::from(t)),
        None => JsValue::null(),
    };

    // Insert the recipe row
    let recipe_stmt = db.prepare(
        "INSERT INTO recipes (id, title, servings, time_minutes, source_json, nutrition_json, cover_json, tags_json, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)"
    );

    recipe_stmt
        .bind(&[
            JsValue::from_str(recipe.id.as_str()),
            JsValue::from_str(&recipe.title),
            servings_val,
            time_val,
            JsValue::from_str(&source_json),
            JsValue::from_str(&nutrition_json),
            JsValue::from_str(&cover_json),
            JsValue::from_str(&tags_json),
            JsValue::from_str(&now),
            JsValue::from_str(&now),
        ])
        .map_err(|e| DbError::QueryFailed(format!("bind failed: {e}")))?
        .run()
        .await
        .map_err(|e| DbError::QueryFailed(format!("run failed: {e}")))?;

    // Insert ingredients
    for (idx, ingredient) in recipe.ingredients.iter().enumerate() {
        let parsed_json = serde_json::to_string(&ingredient.parsed)
            .map_err(|e| DbError::SerializationError(e.to_string()))?;
        let resolution_json = serde_json::to_string(&ingredient.resolution)
            .map_err(|e| DbError::SerializationError(e.to_string()))?;

        let ingredient_id = format!("{}_{}", recipe.id.as_str(), idx);

        let stmt = db.prepare(
            "INSERT INTO recipe_ingredients (id, recipe_id, position, raw_text, parsed_json, resolution_json) VALUES (?1, ?2, ?3, ?4, ?5, ?6)"
        );

        stmt.bind(&[
            JsValue::from_str(&ingredient_id),
            JsValue::from_str(recipe.id.as_str()),
            JsValue::from_f64(idx as f64),
            JsValue::from_str(&ingredient.parsed.name),
            JsValue::from_str(&parsed_json),
            JsValue::from_str(&resolution_json),
        ])
        .map_err(|e| DbError::QueryFailed(format!("bind failed: {e}")))?
        .run()
        .await
        .map_err(|e| DbError::QueryFailed(format!("run failed: {e}")))?;
    }

    // Insert steps
    for step in &recipe.steps {
        let step_id = format!("{}_{}", recipe.id.as_str(), step.number);

        let step_time_val = match step.time_minutes {
            Some(t) => JsValue::from_f64(f64::from(t)),
            None => JsValue::null(),
        };

        let stmt = db.prepare(
            "INSERT INTO recipe_steps (id, recipe_id, step_number, instruction, time_minutes) VALUES (?1, ?2, ?3, ?4, ?5)"
        );

        stmt.bind(&[
            JsValue::from_str(&step_id),
            JsValue::from_str(recipe.id.as_str()),
            JsValue::from_f64(f64::from(step.number)),
            JsValue::from_str(&step.instruction),
            step_time_val,
        ])
        .map_err(|e| DbError::QueryFailed(format!("bind failed: {e}")))?
        .run()
        .await
        .map_err(|e| DbError::QueryFailed(format!("run failed: {e}")))?;
    }

    Ok(())
}

/// Upserts a user's recipe view (save, favorite, notes, patches).
///
/// # Arguments
///
/// * `db` — D1 database binding.
/// * `view` — The user recipe view to persist.
///
/// # Errors
///
/// Returns `DbError` on query or serialization failure.
#[cfg(target_arch = "wasm32")]
pub async fn upsert_user_recipe_view(
    db: &worker::d1::D1Database,
    view: &UserRecipeView,
) -> Result<(), DbError> {
    use worker::wasm_bindgen::JsValue;

    let patches_json = serde_json::to_string(&view.patches)
        .map_err(|e| DbError::SerializationError(e.to_string()))?;
    let now = chrono::Utc::now().to_rfc3339();

    let notes_val = match &view.notes {
        Some(n) => JsValue::from_str(n),
        None => JsValue::null(),
    };

    let statement = db.prepare(
        "INSERT INTO user_recipe_views (recipe_id, user_id, saved, favorite, notes, patches_json, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8) ON CONFLICT(recipe_id, user_id) DO UPDATE SET saved = ?3, favorite = ?4, notes = ?5, patches_json = ?6, updated_at = ?8"
    );

    statement
        .bind(&[
            JsValue::from_str(view.recipe_id.as_str()),
            JsValue::from_str(view.user_id.as_str()),
            JsValue::from_f64(f64::from(i32::from(view.saved))),
            JsValue::from_f64(f64::from(i32::from(view.favorite))),
            notes_val,
            JsValue::from_str(&patches_json),
            JsValue::from_str(&now),
            JsValue::from_str(&now),
        ])
        .map_err(|e| DbError::QueryFailed(format!("bind failed: {e}")))?
        .run()
        .await
        .map_err(|e| DbError::QueryFailed(format!("run failed: {e}")))?;

    Ok(())
}

// Verify domain types are importable on non-wasm targets (catches breakage early).
#[cfg(not(target_arch = "wasm32"))]
const _: () = {
    fn _assert_types_exist() {
        let _ = std::any::type_name::<crate::types::capture::CaptureInput>();
        let _ = std::any::type_name::<crate::types::capture::ExtractionArtifact>();
        let _ = std::any::type_name::<crate::types::ids::CaptureId>();
        let _ = std::any::type_name::<crate::types::ids::RecipeId>();
        let _ = std::any::type_name::<crate::types::ids::UserId>();
        let _ = std::any::type_name::<crate::types::ingredient::ResolvedIngredient>();
        let _ = std::any::type_name::<crate::types::nutrition::NutritionComputation>();
        let _ = std::any::type_name::<crate::types::recipe::CoverOutput>();
        let _ = std::any::type_name::<crate::types::recipe::RecipePatch>();
        let _ = std::any::type_name::<crate::types::recipe::ResolvedRecipe>();
        let _ = std::any::type_name::<crate::types::recipe::Source>();
        let _ = std::any::type_name::<crate::types::recipe::Step>();
        let _ = std::any::type_name::<crate::types::recipe::UserRecipeView>();
    }
};

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn db_error_display_query_failed() {
        let err = DbError::QueryFailed("connection lost".to_string());
        assert_eq!(err.to_string(), "query failed: connection lost");
    }

    #[test]
    fn db_error_display_serialization_error() {
        let err = DbError::SerializationError("invalid UTF-8".to_string());
        assert_eq!(err.to_string(), "serialization error: invalid UTF-8");
    }

    #[test]
    fn db_error_display_not_found() {
        let err = DbError::NotFound {
            entity: "recipe".to_string(),
            id: "recipe_123".to_string(),
        };
        assert_eq!(err.to_string(), "not found: recipe with id recipe_123");
    }
}
