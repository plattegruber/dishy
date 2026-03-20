//! Queue-based async capture pipeline using Cloudflare Queues.
//!
//! Non-trivial captures (social links, screenshots) are processed
//! asynchronously via a Cloudflare Queue. The HTTP handler enqueues a
//! `CaptureJob` message and immediately returns 202 Accepted with the
//! capture ID. A queue consumer picks up the job, runs extraction through
//! the appropriate service (social / OCR), feeds the result into the
//! Claude structuring pipeline, and updates the D1 capture record with
//! the final pipeline state.
//!
//! The state machine transitions follow SPEC §10:
//! ```text
//! Received → Processing → Extracted → Resolved
//!                                    ↘ Failed
//! ```

use serde::{Deserialize, Serialize};

/// A capture job message sent through the Cloudflare Queue.
///
/// Contains all information needed by the queue consumer to process
/// the capture asynchronously. The `capture_id` references the
/// `capture_inputs` row in D1 that was created by the HTTP handler.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CaptureJob {
    /// The capture input ID (references D1 capture_inputs.id).
    pub capture_id: String,
    /// The authenticated user who initiated the capture.
    pub user_id: String,
    /// The type of capture: "social_link" or "screenshot".
    pub input_type: String,
    /// For social_link: the URL to fetch. For screenshot: the base64 image data.
    pub payload: String,
}

/// Response returned for async captures (202 Accepted).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AsyncCaptureResponse {
    /// The capture ID to poll for status.
    pub capture_id: String,
    /// Human-readable status message.
    pub status: String,
    /// The current pipeline state.
    pub pipeline_state: String,
}

/// Response returned when polling capture status.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CaptureStatusResponse {
    /// The capture ID.
    pub capture_id: String,
    /// The current pipeline state.
    pub pipeline_state: String,
    /// The recipe ID, if the capture has been resolved.
    pub recipe_id: Option<String>,
    /// Error message, if the capture failed.
    pub error_message: Option<String>,
}

/// Processes a single capture job from the queue.
///
/// This is the core queue consumer logic. It:
/// 1. Updates the capture state to `Processing`.
/// 2. Runs the appropriate extraction service (social / OCR).
/// 3. Feeds the extracted text into the Claude structuring pipeline.
/// 4. Assembles the recipe and saves it to D1.
/// 5. Updates the capture state to `Resolved` (or `Failed`).
///
/// # Arguments
///
/// * `job` - The capture job to process.
/// * `db` - The D1 database binding.
/// * `api_key` - The Anthropic API key.
/// * `fdc_api_key` - The USDA FDC API key.
/// * `logger` - The request logger for structured logging.
///
/// # Errors
///
/// On failure, the capture state is updated to `Failed` with the error
/// message. The function itself returns `Ok(())` to acknowledge the
/// queue message (preventing infinite retries for non-transient errors).
#[cfg(target_arch = "wasm32")]
pub async fn process_capture_job(
    job: &CaptureJob,
    db: &worker::d1::D1Database,
    api_key: &str,
    fdc_api_key: &str,
    logger: &crate::logging::Logger,
) -> Result<(), String> {
    use crate::db::queries;
    use crate::pipeline::contracts::{
        assemble_recipe, compute_nutrition, generate_cover, parse_ingredients, resolve_ingredients,
        AssemblyInput, CoverInput,
    };
    use crate::services::extraction::extract_recipe_from_text;
    use crate::services::ocr::extract_text_from_image;
    use crate::services::social;
    use crate::types::ids::{CaptureId, UserId};
    use crate::types::recipe::{Source, Step};
    use std::collections::HashMap;

    logger.info(
        "Processing capture job from queue",
        HashMap::from([
            (
                "capture_id".to_string(),
                serde_json::Value::String(job.capture_id.clone()),
            ),
            (
                "input_type".to_string(),
                serde_json::Value::String(job.input_type.clone()),
            ),
        ]),
    );

    // Transition: Received → Processing
    if let Err(e) = update_pipeline_state(db, &job.capture_id, "processing", None, None).await {
        logger.error(
            "Failed to update pipeline state to processing",
            HashMap::from([("error".to_string(), serde_json::Value::String(e.clone()))]),
        );
        return Err(e);
    }

    // Step 1: Extract text from the input
    let extracted_text = match job.input_type.as_str() {
        "social_link" => {
            if let Err(e) = social::validate_url(&job.payload) {
                let msg = format!("invalid URL: {e}");
                let _ =
                    update_pipeline_state(db, &job.capture_id, "failed", Some(&msg), None).await;
                return Err(msg);
            }

            match social::fetch_page_text(&job.payload, logger).await {
                Ok(text) => text,
                Err(e) => {
                    let msg = format!("social link extraction failed: {e}");
                    let _ = update_pipeline_state(db, &job.capture_id, "failed", Some(&msg), None)
                        .await;
                    return Err(msg);
                }
            }
        }
        "screenshot" => {
            let image_data =
                base64::Engine::decode(&base64::engine::general_purpose::STANDARD, &job.payload)
                    .map_err(|e| format!("invalid base64 image data: {e}"))?;

            match extract_text_from_image(&image_data, api_key, logger).await {
                Ok(text) => text,
                Err(e) => {
                    let msg = format!("OCR extraction failed: {e}");
                    let _ = update_pipeline_state(db, &job.capture_id, "failed", Some(&msg), None)
                        .await;
                    return Err(msg);
                }
            }
        }
        other => {
            let msg = format!("unsupported input type for queue processing: {other}");
            let _ = update_pipeline_state(db, &job.capture_id, "failed", Some(&msg), None).await;
            return Err(msg);
        }
    };

    // Step 2: Feed text into Claude extraction pipeline
    let candidate = match extract_recipe_from_text(&extracted_text, api_key, logger).await {
        Ok(c) => c,
        Err(e) => {
            let msg = format!("recipe extraction failed: {e}");
            let _ = update_pipeline_state(db, &job.capture_id, "failed", Some(&msg), None).await;
            return Err(msg);
        }
    };

    // Transition: Processing → Extracted
    let _ = update_pipeline_state(db, &job.capture_id, "extracted", None, None).await;

    // Step 3: Parse ingredients, resolve, compute nutrition
    let ingredient_lines = parse_ingredients(&candidate, api_key, logger).await;
    let resolved_ingredients = resolve_ingredients(&ingredient_lines, fdc_api_key, logger).await;
    let nutrition = compute_nutrition(
        &resolved_ingredients,
        candidate.servings,
        fdc_api_key,
        logger,
    )
    .await;
    let cover = generate_cover(&CoverInput {
        images: vec![],
        title: candidate.title.clone().unwrap_or_default(),
    })
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

    // Determine source based on input type
    let platform = if job.input_type == "social_link" {
        social::detect_platform(&job.payload)
    } else {
        crate::types::recipe::Platform::Manual
    };

    let source = Source {
        platform,
        url: if job.input_type == "social_link" {
            Some(job.payload.clone())
        } else {
            None
        },
        creator_handle: None,
        creator_id: None,
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
        source,
        nutrition,
        cover,
        tags: candidate.tags,
    };

    let recipe = match assemble_recipe(&assembly_input).await {
        Ok(r) => r,
        Err(e) => {
            let msg = format!("recipe assembly failed: {e}");
            let _ = update_pipeline_state(db, &job.capture_id, "failed", Some(&msg), None).await;
            return Err(msg);
        }
    };

    // Step 4: Save recipe to D1
    let capture_id = CaptureId::new(&job.capture_id);
    let user_id = UserId::new(&job.user_id);

    if let Err(e) = queries::insert_recipe(db, &recipe, &user_id, Some(&capture_id)).await {
        let msg = format!("failed to save recipe: {e}");
        let _ = update_pipeline_state(db, &job.capture_id, "failed", Some(&msg), None).await;
        return Err(msg);
    }

    // Transition: Extracted → Resolved
    let _ = update_pipeline_state(
        db,
        &job.capture_id,
        "resolved",
        None,
        Some(recipe.id.as_str()),
    )
    .await;

    logger.info(
        "Capture job processed successfully",
        HashMap::from([
            (
                "capture_id".to_string(),
                serde_json::Value::String(job.capture_id.clone()),
            ),
            (
                "recipe_id".to_string(),
                serde_json::Value::String(recipe.id.as_str().to_string()),
            ),
        ]),
    );

    Ok(())
}

/// Updates the pipeline state of a capture in D1.
///
/// Also optionally sets the error_message and recipe_id columns.
#[cfg(target_arch = "wasm32")]
async fn update_pipeline_state(
    db: &worker::d1::D1Database,
    capture_id: &str,
    state: &str,
    error_message: Option<&str>,
    recipe_id: Option<&str>,
) -> Result<(), String> {
    use worker::wasm_bindgen::JsValue;

    let now = chrono::Utc::now().to_rfc3339();
    let error_val = match error_message {
        Some(msg) => JsValue::from_str(msg),
        None => JsValue::null(),
    };
    let recipe_id_val = match recipe_id {
        Some(id) => JsValue::from_str(id),
        None => JsValue::null(),
    };

    let statement = db.prepare(
        "UPDATE capture_inputs SET pipeline_state = ?1, error_message = ?2, recipe_id = ?3, updated_at = ?4 WHERE id = ?5"
    );

    statement
        .bind(&[
            JsValue::from_str(state),
            error_val,
            recipe_id_val,
            JsValue::from_str(&now),
            JsValue::from_str(capture_id),
        ])
        .map_err(|e| format!("bind failed: {e}"))?
        .run()
        .await
        .map_err(|e| format!("update failed: {e}"))?;

    Ok(())
}

/// Non-WASM stub for testing.
#[cfg(not(target_arch = "wasm32"))]
pub async fn process_capture_job(
    _job: &CaptureJob,
    _api_key: &str,
    _fdc_api_key: &str,
    _logger: &crate::logging::Logger,
) -> Result<(), String> {
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn capture_job_roundtrips() {
        let job = CaptureJob {
            capture_id: "cap_123".to_string(),
            user_id: "user_abc".to_string(),
            input_type: "social_link".to_string(),
            payload: "https://instagram.com/p/abc".to_string(),
        };
        let json = serde_json::to_string(&job).expect("should serialize");
        let deserialized: CaptureJob = serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(deserialized.capture_id, "cap_123");
        assert_eq!(deserialized.input_type, "social_link");
    }

    #[test]
    fn async_capture_response_roundtrips() {
        let resp = AsyncCaptureResponse {
            capture_id: "cap_456".to_string(),
            status: "queued".to_string(),
            pipeline_state: "received".to_string(),
        };
        let json = serde_json::to_string(&resp).expect("should serialize");
        let deserialized: AsyncCaptureResponse =
            serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(deserialized.capture_id, "cap_456");
        assert_eq!(deserialized.pipeline_state, "received");
    }

    #[test]
    fn capture_status_response_roundtrips_pending() {
        let resp = CaptureStatusResponse {
            capture_id: "cap_789".to_string(),
            pipeline_state: "processing".to_string(),
            recipe_id: None,
            error_message: None,
        };
        let json = serde_json::to_string(&resp).expect("should serialize");
        let deserialized: CaptureStatusResponse =
            serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(deserialized.pipeline_state, "processing");
        assert!(deserialized.recipe_id.is_none());
    }

    #[test]
    fn capture_status_response_roundtrips_resolved() {
        let resp = CaptureStatusResponse {
            capture_id: "cap_999".to_string(),
            pipeline_state: "resolved".to_string(),
            recipe_id: Some("recipe_001".to_string()),
            error_message: None,
        };
        let json = serde_json::to_string(&resp).expect("should serialize");
        let deserialized: CaptureStatusResponse =
            serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(deserialized.pipeline_state, "resolved");
        assert_eq!(deserialized.recipe_id.as_deref(), Some("recipe_001"));
    }

    #[test]
    fn capture_status_response_roundtrips_failed() {
        let resp = CaptureStatusResponse {
            capture_id: "cap_000".to_string(),
            pipeline_state: "failed".to_string(),
            recipe_id: None,
            error_message: Some("extraction timed out".to_string()),
        };
        let json = serde_json::to_string(&resp).expect("should serialize");
        let deserialized: CaptureStatusResponse =
            serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(deserialized.pipeline_state, "failed");
        assert_eq!(
            deserialized.error_message.as_deref(),
            Some("extraction timed out")
        );
    }

    #[tokio::test]
    async fn process_capture_job_stub_succeeds() {
        let logger = crate::logging::Logger::new("test".to_string(), "test".to_string());
        let job = CaptureJob {
            capture_id: "cap_test".to_string(),
            user_id: "user_test".to_string(),
            input_type: "social_link".to_string(),
            payload: "https://example.com/recipe".to_string(),
        };
        let result = process_capture_job(&job, "fake-key", "fake-fdc", &logger).await;
        assert!(result.is_ok());
    }
}
