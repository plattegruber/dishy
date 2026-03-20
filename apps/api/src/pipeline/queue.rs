//! Cloudflare Queue consumer for async capture processing.
//!
//! Social link and screenshot captures are enqueued as messages and processed
//! asynchronously by this consumer. Each message contains a capture ID that
//! references a row in the `capture_inputs` D1 table. The consumer:
//!
//! 1. Reads the capture input from D1.
//! 2. Runs the appropriate extraction pipeline (social fetch or OCR).
//! 3. Assembles the recipe and saves it to D1.
//! 4. Updates the capture input with the recipe ID or error message.
//!
//! ## Queue Message Format
//!
//! Messages are JSON-serialized [`CaptureQueueMessage`] structs containing
//! the capture ID and the user ID.

use serde::{Deserialize, Serialize};

/// A message sent to the capture processing queue.
///
/// Contains the identifiers needed to look up the capture input
/// in D1 and associate the result with the correct user.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CaptureQueueMessage {
    /// The capture input ID (primary key in capture_inputs table).
    pub capture_id: String,
    /// The user who initiated the capture.
    pub user_id: String,
}

/// Processes a single capture queue message.
///
/// Looks up the capture input in D1, runs the extraction pipeline
/// for the input type (social link or screenshot), assembles the
/// recipe, and persists everything back to D1.
///
/// # Arguments
///
/// * `msg` - The queue message with capture and user IDs.
/// * `env` - The Worker environment for D1, R2, and secret access.
///
/// # Errors
///
/// Returns a string error message on failure. The caller should
/// update the capture input's pipeline_state to "failed" and store
/// the error message.
#[cfg(target_arch = "wasm32")]
pub async fn process_capture(msg: &CaptureQueueMessage, env: &worker::Env) -> Result<(), String> {
    use crate::db::queries;
    use crate::logging::Logger;
    use crate::pipeline::contracts::{
        assemble_recipe, compute_nutrition, generate_cover, parse_ingredients, resolve_ingredients,
        AssemblyInput, CoverInput,
    };
    use crate::types::capture::CaptureInput;
    use crate::types::ids::{CaptureId, RecipeId, UserId};
    use crate::types::recipe::{Platform, Source, Step};
    use std::collections::HashMap;
    use worker::wasm_bindgen::JsValue;

    let logger = Logger::new(uuid::Uuid::new_v4().to_string(), String::new());

    logger.info(
        "Processing capture queue message",
        HashMap::from([
            (
                "capture_id".to_string(),
                serde_json::Value::String(msg.capture_id.clone()),
            ),
            (
                "user_id".to_string(),
                serde_json::Value::String(msg.user_id.clone()),
            ),
        ]),
    );

    let db = env
        .d1("DB")
        .map_err(|e| format!("failed to get D1 binding: {e}"))?;

    let api_key = env
        .secret("ANTHROPIC_API_KEY")
        .map(|s| s.to_string())
        .unwrap_or_default();

    if api_key.is_empty() {
        return Err("ANTHROPIC_API_KEY not configured".to_string());
    }

    // Read the capture input from D1
    let capture_stmt = db.prepare(
        "SELECT input_type, input_data FROM capture_inputs WHERE id = ?1 AND user_id = ?2",
    );
    let capture_result = capture_stmt
        .bind(&[
            JsValue::from_str(&msg.capture_id),
            JsValue::from_str(&msg.user_id),
        ])
        .map_err(|e| format!("bind failed: {e}"))?
        .all()
        .await
        .map_err(|e| format!("query failed: {e}"))?;

    let rows = capture_result
        .results::<serde_json::Value>()
        .map_err(|e| format!("results parse failed: {e}"))?;

    let row = rows
        .into_iter()
        .next()
        .ok_or_else(|| format!("capture input not found: {}", msg.capture_id))?;

    let input_data_str = row["input_data"]
        .as_str()
        .ok_or_else(|| "missing input_data column".to_string())?;

    let capture_input: CaptureInput = serde_json::from_str(input_data_str)
        .map_err(|e| format!("failed to parse capture input: {e}"))?;

    // Update pipeline state to 'processing'
    let update_stmt = db.prepare(
        "UPDATE capture_inputs SET pipeline_state = 'processing', updated_at = ?1 WHERE id = ?2",
    );
    let now = chrono::Utc::now().to_rfc3339();
    let _ = update_stmt
        .bind(&[JsValue::from_str(&now), JsValue::from_str(&msg.capture_id)])
        .map_err(|e| format!("bind failed: {e}"))?
        .run()
        .await;

    // Run extraction based on input type
    let candidate = match &capture_input {
        CaptureInput::SocialLink { url } => {
            logger.info(
                "Processing social link capture",
                HashMap::from([("url".to_string(), serde_json::Value::String(url.clone()))]),
            );
            crate::services::social::extract_recipe_from_url(url, &api_key, &logger)
                .await
                .map_err(|e| format!("social extraction failed: {e}"))?
        }
        CaptureInput::Screenshot { image } => {
            logger.info(
                "Processing screenshot capture",
                HashMap::from([(
                    "asset_id".to_string(),
                    serde_json::Value::String(image.as_str().to_string()),
                )]),
            );

            // Retrieve image from R2
            let bucket = env
                .bucket("IMAGES")
                .map_err(|e| format!("failed to get R2 bucket: {e}"))?;

            let retrieve_result =
                crate::services::storage::retrieve_image(&bucket, image.as_str(), &logger)
                    .await
                    .map_err(|e| format!("failed to retrieve screenshot from R2: {e}"))?;

            crate::services::ocr::extract_recipe_from_image(
                &retrieve_result.data,
                &retrieve_result.content_type,
                &api_key,
                &logger,
            )
            .await
            .map_err(|e| format!("OCR extraction failed: {e}"))?
        }
        other => {
            return Err(format!(
                "unexpected input type for queue processing: {other:?}"
            ));
        }
    };

    // Get FDC API key (optional)
    let fdc_api_key = env
        .secret("FDC_API_KEY")
        .map(|s| s.to_string())
        .unwrap_or_default();

    // Parse and resolve ingredients
    let ingredient_lines = parse_ingredients(&candidate, &api_key, &logger).await;
    let resolved_ingredients = resolve_ingredients(&ingredient_lines, &fdc_api_key, &logger).await;

    // Compute nutrition
    let nutrition = compute_nutrition(
        &resolved_ingredients,
        candidate.servings,
        &fdc_api_key,
        &logger,
    )
    .await;

    // Generate cover
    let images_bucket = env.bucket("IMAGES").ok();
    let cover = generate_cover(
        &CoverInput {
            images: vec![],
            title: candidate.title.clone().unwrap_or_default(),
        },
        images_bucket.as_ref(),
        Some(&logger),
    )
    .await;

    // Build steps
    let steps: Vec<Step> = candidate
        .steps
        .iter()
        .enumerate()
        .map(|(i, instruction)| Step {
            number: (i + 1) as i32,
            instruction: instruction.clone(),
            time_minutes: None,
        })
        .collect();

    // Determine source
    let (platform, url) = match &capture_input {
        CaptureInput::SocialLink { url } => (
            crate::services::social::detect_platform(url),
            Some(url.clone()),
        ),
        _ => (Platform::Unknown, None),
    };

    let title = candidate
        .title
        .clone()
        .unwrap_or_else(|| "Untitled Recipe".to_string());

    let assembly_input = AssemblyInput {
        title,
        ingredients: resolved_ingredients,
        steps,
        servings: candidate.servings,
        time_minutes: candidate.time_minutes,
        source: Source {
            platform,
            url,
            creator_handle: None,
            creator_id: None,
        },
        nutrition,
        cover,
        tags: candidate.tags,
    };

    let recipe = assemble_recipe(&assembly_input)
        .await
        .map_err(|e| format!("recipe assembly failed: {e}"))?;

    let user_id = UserId::new(&msg.user_id);
    let capture_id = CaptureId::new(&msg.capture_id);

    // Save recipe to D1
    queries::insert_recipe(&db, &recipe, &user_id, Some(&capture_id))
        .await
        .map_err(|e| format!("failed to save recipe: {e}"))?;

    // Update capture input with recipe_id and resolved state
    let now2 = chrono::Utc::now().to_rfc3339();
    let resolve_stmt = db.prepare(
        "UPDATE capture_inputs SET pipeline_state = 'resolved', recipe_id = ?1, updated_at = ?2 WHERE id = ?3",
    );
    resolve_stmt
        .bind(&[
            JsValue::from_str(recipe.id.as_str()),
            JsValue::from_str(&now2),
            JsValue::from_str(&msg.capture_id),
        ])
        .map_err(|e| format!("bind failed: {e}"))?
        .run()
        .await
        .map_err(|e| format!("update failed: {e}"))?;

    logger.info(
        "Capture queue processing complete",
        HashMap::from([
            (
                "capture_id".to_string(),
                serde_json::Value::String(msg.capture_id.clone()),
            ),
            (
                "recipe_id".to_string(),
                serde_json::Value::String(recipe.id.as_str().to_string()),
            ),
        ]),
    );

    // Best-effort flush logs
    let axiom_token = env
        .secret("AXIOM_API_TOKEN")
        .map(|s| s.to_string())
        .unwrap_or_default();
    let axiom_dataset = env
        .var("AXIOM_DATASET")
        .map(|v| v.to_string())
        .unwrap_or_else(|_| "dishy-api".to_string());

    if !axiom_token.is_empty() {
        let _ = logger.flush(&axiom_token, &axiom_dataset).await;
    }

    Ok(())
}

/// Marks a capture input as failed in D1.
///
/// Updates the pipeline_state to "failed" and stores the error message.
#[cfg(target_arch = "wasm32")]
pub async fn mark_capture_failed(
    db: &worker::d1::D1Database,
    capture_id: &str,
    error_message: &str,
) -> Result<(), String> {
    use worker::wasm_bindgen::JsValue;

    let now = chrono::Utc::now().to_rfc3339();
    let stmt = db.prepare(
        "UPDATE capture_inputs SET pipeline_state = 'failed', error_message = ?1, updated_at = ?2 WHERE id = ?3",
    );
    stmt.bind(&[
        JsValue::from_str(error_message),
        JsValue::from_str(&now),
        JsValue::from_str(capture_id),
    ])
    .map_err(|e| format!("bind failed: {e}"))?
    .run()
    .await
    .map_err(|e| format!("update failed: {e}"))?;

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn capture_queue_message_roundtrips() {
        let msg = CaptureQueueMessage {
            capture_id: "cap_123".to_string(),
            user_id: "user_456".to_string(),
        };
        let json = serde_json::to_string(&msg).expect("should serialize");
        let deserialized: CaptureQueueMessage =
            serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(deserialized.capture_id, "cap_123");
        assert_eq!(deserialized.user_id, "user_456");
    }

    #[test]
    fn capture_queue_message_serializes_expected_fields() {
        let msg = CaptureQueueMessage {
            capture_id: "cap_abc".to_string(),
            user_id: "user_def".to_string(),
        };
        let json = serde_json::to_value(&msg).expect("should serialize");
        assert_eq!(json["capture_id"], "cap_abc");
        assert_eq!(json["user_id"], "user_def");
    }
}
