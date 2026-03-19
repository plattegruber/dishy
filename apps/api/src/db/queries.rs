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

use crate::types::capture::{CaptureInput, ExtractionArtifact};
use crate::types::ids::{CaptureId, RecipeId, UserId};
use crate::types::ingredient::ResolvedIngredient;
use crate::types::nutrition::NutritionComputation;
use crate::types::recipe::{
    CoverOutput, RecipePatch, ResolvedRecipe, Source, Step, UserRecipeView,
};

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
            worker::d1::D1Type::Text(id.as_str().to_string()),
            worker::d1::D1Type::Text(user_id.as_str().to_string()),
            worker::d1::D1Type::Text(input_type.to_string()),
            worker::d1::D1Type::Text(input_data),
            worker::d1::D1Type::Text(now.clone()),
            worker::d1::D1Type::Text(now),
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

    statement
        .bind(&[
            worker::d1::D1Type::Text(artifact_id.to_string()),
            worker::d1::D1Type::Text(artifact.id.as_str().to_string()),
            worker::d1::D1Type::Integer(artifact.version as i32),
            match &artifact.raw_text {
                Some(t) => worker::d1::D1Type::Text(t.clone()),
                None => worker::d1::D1Type::Null,
            },
            match &artifact.ocr_text {
                Some(t) => worker::d1::D1Type::Text(t.clone()),
                None => worker::d1::D1Type::Null,
            },
            match &artifact.transcript {
                Some(t) => worker::d1::D1Type::Text(t.clone()),
                None => worker::d1::D1Type::Null,
            },
            worker::d1::D1Type::Text(ingredients_json),
            worker::d1::D1Type::Text(steps_json),
            worker::d1::D1Type::Text(images_json),
            worker::d1::D1Type::Text(source_json),
            worker::d1::D1Type::Real(artifact.confidence),
            worker::d1::D1Type::Text(now),
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
    let source_json = serde_json::to_string(&recipe.source)
        .map_err(|e| DbError::SerializationError(e.to_string()))?;
    let nutrition_json = serde_json::to_string(&recipe.nutrition)
        .map_err(|e| DbError::SerializationError(e.to_string()))?;
    let cover_json = serde_json::to_string(&recipe.cover)
        .map_err(|e| DbError::SerializationError(e.to_string()))?;
    let tags_json = serde_json::to_string(&recipe.tags)
        .map_err(|e| DbError::SerializationError(e.to_string()))?;

    let now = chrono::Utc::now().to_rfc3339();

    // Insert the recipe row
    let recipe_stmt = db.prepare(
        "INSERT INTO recipes (id, title, servings, time_minutes, source_json, nutrition_json, cover_json, tags_json, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)"
    );

    recipe_stmt
        .bind(&[
            worker::d1::D1Type::Text(recipe.id.as_str().to_string()),
            worker::d1::D1Type::Text(recipe.title.clone()),
            match recipe.servings {
                Some(s) => worker::d1::D1Type::Integer(s),
                None => worker::d1::D1Type::Null,
            },
            match recipe.time_minutes {
                Some(t) => worker::d1::D1Type::Integer(t),
                None => worker::d1::D1Type::Null,
            },
            worker::d1::D1Type::Text(source_json),
            worker::d1::D1Type::Text(nutrition_json),
            worker::d1::D1Type::Text(cover_json),
            worker::d1::D1Type::Text(tags_json),
            worker::d1::D1Type::Text(now.clone()),
            worker::d1::D1Type::Text(now.clone()),
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
            worker::d1::D1Type::Text(ingredient_id),
            worker::d1::D1Type::Text(recipe.id.as_str().to_string()),
            worker::d1::D1Type::Integer(idx as i32),
            worker::d1::D1Type::Text(ingredient.parsed.name.clone()),
            worker::d1::D1Type::Text(parsed_json),
            worker::d1::D1Type::Text(resolution_json),
        ])
        .map_err(|e| DbError::QueryFailed(format!("bind failed: {e}")))?
        .run()
        .await
        .map_err(|e| DbError::QueryFailed(format!("run failed: {e}")))?;
    }

    // Insert steps
    for step in &recipe.steps {
        let step_id = format!("{}_{}", recipe.id.as_str(), step.number);

        let stmt = db.prepare(
            "INSERT INTO recipe_steps (id, recipe_id, step_number, instruction, time_minutes) VALUES (?1, ?2, ?3, ?4, ?5)"
        );

        stmt.bind(&[
            worker::d1::D1Type::Text(step_id),
            worker::d1::D1Type::Text(recipe.id.as_str().to_string()),
            worker::d1::D1Type::Integer(step.number),
            worker::d1::D1Type::Text(step.instruction.clone()),
            match step.time_minutes {
                Some(t) => worker::d1::D1Type::Integer(t),
                None => worker::d1::D1Type::Null,
            },
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
    let patches_json = serde_json::to_string(&view.patches)
        .map_err(|e| DbError::SerializationError(e.to_string()))?;
    let now = chrono::Utc::now().to_rfc3339();

    let statement = db.prepare(
        "INSERT INTO user_recipe_views (recipe_id, user_id, saved, favorite, notes, patches_json, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8) ON CONFLICT(recipe_id, user_id) DO UPDATE SET saved = ?3, favorite = ?4, notes = ?5, patches_json = ?6, updated_at = ?8"
    );

    statement
        .bind(&[
            worker::d1::D1Type::Text(view.recipe_id.as_str().to_string()),
            worker::d1::D1Type::Text(view.user_id.as_str().to_string()),
            worker::d1::D1Type::Integer(i32::from(view.saved)),
            worker::d1::D1Type::Integer(i32::from(view.favorite)),
            match &view.notes {
                Some(n) => worker::d1::D1Type::Text(n.clone()),
                None => worker::d1::D1Type::Null,
            },
            worker::d1::D1Type::Text(patches_json),
            worker::d1::D1Type::Text(now.clone()),
            worker::d1::D1Type::Text(now),
        ])
        .map_err(|e| DbError::QueryFailed(format!("bind failed: {e}")))?
        .run()
        .await
        .map_err(|e| DbError::QueryFailed(format!("run failed: {e}")))?;

    Ok(())
}

// Silence unused import warnings for non-wasm targets (types used in wasm-gated functions)
#[cfg(not(target_arch = "wasm32"))]
const _: () = {
    fn _assert_types_used() {
        let _ = std::any::type_name::<CaptureInput>();
        let _ = std::any::type_name::<ExtractionArtifact>();
        let _ = std::any::type_name::<CaptureId>();
        let _ = std::any::type_name::<RecipeId>();
        let _ = std::any::type_name::<UserId>();
        let _ = std::any::type_name::<ResolvedIngredient>();
        let _ = std::any::type_name::<NutritionComputation>();
        let _ = std::any::type_name::<CoverOutput>();
        let _ = std::any::type_name::<RecipePatch>();
        let _ = std::any::type_name::<ResolvedRecipe>();
        let _ = std::any::type_name::<Source>();
        let _ = std::any::type_name::<Step>();
        let _ = std::any::type_name::<UserRecipeView>();
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
