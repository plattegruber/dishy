//! Recipe capture and retrieval route handlers.
//!
//! Implements the recipe endpoints:
//! - `POST /recipes/capture` -- manual=sync, social_link/screenshot=async (202)
//! - `GET /captures/:id` -- poll capture status for async captures
//! - `GET /recipes` -- list all recipes for the authenticated user
//! - `GET /recipes/:id` -- get a single recipe by ID
//!
//! All endpoints require authentication via Clerk JWT.

#[cfg(target_arch = "wasm32")]
use std::collections::HashMap;

#[cfg(target_arch = "wasm32")]
use serde::{Deserialize, Serialize};

/// Request body for the capture endpoint.
///
/// Supports three input types:
/// - `"manual"`: synchronous, requires `text` field
/// - `"social_link"`: async via queue, requires `url` field
/// - `"screenshot"`: async via queue, requires `image_data` (base64) and `content_type`
#[cfg(target_arch = "wasm32")]
#[derive(Debug, Deserialize)]
pub struct CaptureRequest {
    /// The type of input: "manual", "social_link", or "screenshot".
    pub input_type: String,
    /// The raw recipe text (required for manual).
    #[serde(default)]
    pub text: String,
    /// The URL to fetch (required for social_link).
    #[serde(default)]
    pub url: String,
    /// Base64-encoded image data (required for screenshot).
    #[serde(default)]
    pub image_data: String,
    /// The MIME type of the image (required for screenshot).
    #[serde(default)]
    pub content_type: String,
}

/// Response for async capture submissions (202 Accepted).
#[cfg(target_arch = "wasm32")]
#[derive(Debug, Serialize)]
struct AsyncCaptureResponse {
    /// The capture ID for polling.
    capture_id: String,
    /// The current pipeline state.
    status: String,
    /// Human-readable message.
    message: String,
}

/// Response for the capture status poll endpoint.
#[cfg(target_arch = "wasm32")]
#[derive(Debug, Serialize)]
struct CaptureStatusResponse {
    /// The capture ID.
    capture_id: String,
    /// The current pipeline state.
    status: String,
    /// Error message if failed.
    error_message: Option<String>,
    /// Recipe ID if resolved.
    recipe_id: Option<String>,
}

/// Error response body for recipe endpoints.
#[cfg(target_arch = "wasm32")]
#[derive(Debug, Serialize)]
struct RecipeErrorResponse {
    /// Nested error object.
    error: RecipeErrorDetail,
}

/// Inner error detail for recipe endpoint errors.
#[cfg(target_arch = "wasm32")]
#[derive(Debug, Serialize)]
struct RecipeErrorDetail {
    /// Machine-readable error code.
    code: String,
    /// Human-readable error message.
    message: String,
}

/// Handles `POST /recipes/capture` -- manual text capture.
///
/// Accepts a JSON body with `input_type` and `text`, runs the capture
/// pipeline (Claude extraction -> structuring -> assembly), saves the
/// recipe to D1, and returns the resolved recipe.
///
/// # Authentication
///
/// Requires a valid Clerk JWT in the `Authorization` header.
///
/// # Request Body
///
/// ```json
/// { "input_type": "manual", "text": "2 cups flour..." }
/// ```
///
/// # Response
///
/// Returns the saved `ResolvedRecipe` as JSON with status 201.
#[cfg(target_arch = "wasm32")]
pub async fn handle_capture(
    mut req: worker::Request,
    ctx: worker::RouteContext<()>,
) -> worker::Result<worker::Response> {
    use crate::db::queries;
    use crate::middleware::{
        attach_correlation_header, authenticate_request, extract_request_context,
    };
    use crate::pipeline::contracts::{
        assemble_recipe, compute_nutrition, generate_cover, parse_ingredients, resolve_ingredients,
        AssemblyInput, CoverInput,
    };
    use crate::services::extraction::extract_recipe_from_text;
    use crate::types::capture::CaptureInput;
    use crate::types::ids::{AssetId, CaptureId, UserId};
    use crate::types::recipe::{Platform, Source, Step};

    let request_ctx = extract_request_context(&req);

    request_ctx.logger.info(
        "Recipe capture requested",
        HashMap::from([(
            "path".to_string(),
            serde_json::Value::String("/recipes/capture".to_string()),
        )]),
    );

    // Authenticate
    let jwks_url = ctx
        .var("CLERK_JWKS_URL")
        .map(|v| v.to_string())
        .unwrap_or_else(|_| "https://api.clerk.com/v1/jwks".to_string());

    let claims = match authenticate_request(&req, &request_ctx, &jwks_url).await {
        Ok(claims) => claims,
        Err(auth_error) => {
            request_ctx.logger.warn(
                "Authentication failed for /recipes/capture",
                HashMap::from([(
                    "error_code".to_string(),
                    serde_json::Value::String(auth_error.code().to_string()),
                )]),
            );
            flush_logs(&request_ctx, &ctx).await;
            let mut resp = auth_error.to_response()?;
            attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
            return Ok(resp);
        }
    };

    let user_id = UserId::new(&claims.sub);

    // Parse request body
    let body_text = req
        .text()
        .await
        .map_err(|e| worker::Error::RustError(format!("failed to read request body: {e}")))?;

    let capture_req: CaptureRequest = match serde_json::from_str(&body_text) {
        Ok(r) => r,
        Err(e) => {
            request_ctx.logger.warn(
                "Invalid request body",
                HashMap::from([(
                    "error".to_string(),
                    serde_json::Value::String(e.to_string()),
                )]),
            );
            flush_logs(&request_ctx, &ctx).await;
            let mut resp = error_response(
                "invalid_request",
                &format!("Invalid request body: {e}"),
                400,
            )?;
            attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
            return Ok(resp);
        }
    };

    // Validate input type
    match capture_req.input_type.as_str() {
        "manual" | "social_link" | "screenshot" => {}
        _ => {
            flush_logs(&request_ctx, &ctx).await;
            let mut resp = error_response(
                "unsupported_input_type",
                &format!(
                    "Unsupported input type: {}. Supported: manual, social_link, screenshot.",
                    capture_req.input_type
                ),
                400,
            )?;
            attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
            return Ok(resp);
        }
    }

    // For social_link and screenshot, handle async via queue
    if capture_req.input_type == "social_link" || capture_req.input_type == "screenshot" {
        return handle_async_capture(capture_req, &user_id, &request_ctx, &ctx).await;
    }

    // Validate text is not empty (manual only)
    if capture_req.text.trim().is_empty() {
        flush_logs(&request_ctx, &ctx).await;
        let mut resp = error_response("empty_text", "Recipe text cannot be empty", 400)?;
        attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
        return Ok(resp);
    }

    // Get the D1 database binding
    let db = ctx
        .env
        .d1("DB")
        .map_err(|e| worker::Error::RustError(format!("failed to get D1 binding: {e}")))?;

    // Create capture input record
    let capture_id = CaptureId::new(uuid::Uuid::new_v4().to_string());
    let capture_input = CaptureInput::Manual {
        text: capture_req.text.clone(),
    };

    request_ctx.logger.info(
        "Saving capture input",
        HashMap::from([
            (
                "stage".to_string(),
                serde_json::Value::String("capture".to_string()),
            ),
            (
                "capture_id".to_string(),
                serde_json::Value::String(capture_id.as_str().to_string()),
            ),
        ]),
    );

    if let Err(e) = queries::insert_capture_input(&db, &capture_id, &user_id, &capture_input).await
    {
        request_ctx.logger.error(
            "Failed to save capture input",
            HashMap::from([(
                "error".to_string(),
                serde_json::Value::String(e.to_string()),
            )]),
        );
        flush_logs(&request_ctx, &ctx).await;
        let mut resp = error_response("db_error", &format!("Failed to save capture: {e}"), 500)?;
        attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
        return Ok(resp);
    }

    // Get the Anthropic API key
    let api_key = ctx
        .secret("ANTHROPIC_API_KEY")
        .map(|s| s.to_string())
        .unwrap_or_default();

    if api_key.is_empty() {
        request_ctx
            .logger
            .error("ANTHROPIC_API_KEY not configured", HashMap::new());
        flush_logs(&request_ctx, &ctx).await;
        let mut resp = error_response("config_error", "ANTHROPIC_API_KEY is not configured", 500)?;
        attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
        return Ok(resp);
    }

    // Run extraction via Claude
    request_ctx.logger.info(
        "Running Claude extraction",
        HashMap::from([(
            "stage".to_string(),
            serde_json::Value::String("extraction".to_string()),
        )]),
    );

    let candidate =
        match extract_recipe_from_text(&capture_req.text, &api_key, &request_ctx.logger).await {
            Ok(c) => c,
            Err(e) => {
                request_ctx.logger.error(
                    "Claude extraction failed",
                    HashMap::from([
                        (
                            "stage".to_string(),
                            serde_json::Value::String("extraction".to_string()),
                        ),
                        (
                            "error".to_string(),
                            serde_json::Value::String(e.to_string()),
                        ),
                    ]),
                );
                flush_logs(&request_ctx, &ctx).await;
                let mut resp = error_response(
                    "extraction_failed",
                    &format!("Recipe extraction failed: {e}"),
                    502,
                )?;
                attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
                return Ok(resp);
            }
        };

    request_ctx.logger.info(
        "Extraction complete, assembling recipe",
        HashMap::from([
            (
                "stage".to_string(),
                serde_json::Value::String("assembly".to_string()),
            ),
            (
                "title".to_string(),
                serde_json::Value::String(candidate.title.clone().unwrap_or_default()),
            ),
        ]),
    );

    // Get the FDC API key (optional -- degrades gracefully)
    let fdc_api_key = ctx
        .secret("FDC_API_KEY")
        .map(|s| s.to_string())
        .unwrap_or_default();

    // Parse and resolve ingredients
    let ingredient_lines = parse_ingredients(&candidate, &api_key, &request_ctx.logger).await;
    let resolved_ingredients =
        resolve_ingredients(&ingredient_lines, &fdc_api_key, &request_ctx.logger).await;

    // Compute nutrition from resolved ingredients
    let nutrition = compute_nutrition(
        &resolved_ingredients,
        candidate.servings,
        &fdc_api_key,
        &request_ctx.logger,
    )
    .await;

    // Generate cover with R2 storage
    let images_bucket = ctx.env.bucket("IMAGES").ok();
    let cover = generate_cover(
        &CoverInput {
            images: vec![],
            title: candidate.title.clone().unwrap_or_default(),
        },
        images_bucket.as_ref(),
        Some(&request_ctx.logger),
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

    // Assemble the recipe
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
            platform: Platform::Manual,
            url: None,
            creator_handle: None,
            creator_id: None,
        },
        nutrition,
        cover,
        tags: candidate.tags,
    };

    let recipe = match assemble_recipe(&assembly_input).await {
        Ok(r) => r,
        Err(e) => {
            request_ctx.logger.error(
                "Recipe assembly failed",
                HashMap::from([(
                    "error".to_string(),
                    serde_json::Value::String(e.to_string()),
                )]),
            );
            flush_logs(&request_ctx, &ctx).await;
            let mut resp = error_response(
                "assembly_failed",
                &format!("Recipe assembly failed: {e}"),
                500,
            )?;
            attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
            return Ok(resp);
        }
    };

    // Save to D1
    request_ctx.logger.info(
        "Saving recipe to D1",
        HashMap::from([
            (
                "stage".to_string(),
                serde_json::Value::String("persist".to_string()),
            ),
            (
                "recipe_id".to_string(),
                serde_json::Value::String(recipe.id.as_str().to_string()),
            ),
        ]),
    );

    if let Err(e) = queries::insert_recipe(&db, &recipe, &user_id, Some(&capture_id)).await {
        request_ctx.logger.error(
            "Failed to save recipe",
            HashMap::from([(
                "error".to_string(),
                serde_json::Value::String(e.to_string()),
            )]),
        );
        flush_logs(&request_ctx, &ctx).await;
        let mut resp = error_response("db_error", &format!("Failed to save recipe: {e}"), 500)?;
        attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
        return Ok(resp);
    }

    request_ctx.logger.info(
        "Recipe capture complete",
        HashMap::from([
            (
                "recipe_id".to_string(),
                serde_json::Value::String(recipe.id.as_str().to_string()),
            ),
            (
                "title".to_string(),
                serde_json::Value::String(recipe.title.clone()),
            ),
        ]),
    );

    flush_logs(&request_ctx, &ctx).await;

    let json =
        serde_json::to_string(&recipe).map_err(|e| worker::Error::RustError(e.to_string()))?;

    let mut resp = worker::Response::ok(json)?;
    let _ = resp.headers_mut().set("Content-Type", "application/json");
    attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
    // Return 201 Created
    Ok(resp.with_status(201))
}

/// Handles `GET /recipes` -- list all recipes for the authenticated user.
///
/// # Authentication
///
/// Requires a valid Clerk JWT in the `Authorization` header.
///
/// # Response
///
/// Returns a JSON array of `ResolvedRecipe` objects.
#[cfg(target_arch = "wasm32")]
pub async fn handle_list_recipes(
    req: worker::Request,
    ctx: worker::RouteContext<()>,
) -> worker::Result<worker::Response> {
    use crate::db::queries;
    use crate::middleware::{
        attach_correlation_header, authenticate_request, extract_request_context,
    };
    use crate::types::ids::UserId;

    let request_ctx = extract_request_context(&req);

    request_ctx.logger.info(
        "Recipe list requested",
        HashMap::from([(
            "path".to_string(),
            serde_json::Value::String("/recipes".to_string()),
        )]),
    );

    // Authenticate
    let jwks_url = ctx
        .var("CLERK_JWKS_URL")
        .map(|v| v.to_string())
        .unwrap_or_else(|_| "https://api.clerk.com/v1/jwks".to_string());

    let claims = match authenticate_request(&req, &request_ctx, &jwks_url).await {
        Ok(claims) => claims,
        Err(auth_error) => {
            flush_logs(&request_ctx, &ctx).await;
            let mut resp = auth_error.to_response()?;
            attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
            return Ok(resp);
        }
    };

    let user_id = UserId::new(&claims.sub);

    let db = ctx
        .env
        .d1("DB")
        .map_err(|e| worker::Error::RustError(format!("failed to get D1 binding: {e}")))?;

    let recipes = match queries::get_recipes_by_user(&db, &user_id).await {
        Ok(r) => r,
        Err(e) => {
            request_ctx.logger.error(
                "Failed to fetch recipes",
                HashMap::from([(
                    "error".to_string(),
                    serde_json::Value::String(e.to_string()),
                )]),
            );
            flush_logs(&request_ctx, &ctx).await;
            let mut resp =
                error_response("db_error", &format!("Failed to fetch recipes: {e}"), 500)?;
            attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
            return Ok(resp);
        }
    };

    request_ctx.logger.info(
        "Recipe list fetched",
        HashMap::from([(
            "count".to_string(),
            serde_json::Value::Number(serde_json::Number::from(recipes.len())),
        )]),
    );

    flush_logs(&request_ctx, &ctx).await;

    let json =
        serde_json::to_string(&recipes).map_err(|e| worker::Error::RustError(e.to_string()))?;

    let mut resp = worker::Response::ok(json)?;
    let _ = resp.headers_mut().set("Content-Type", "application/json");
    attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
    Ok(resp)
}

/// Handles `GET /recipes/:id` -- get a single recipe by ID.
///
/// # Authentication
///
/// Requires a valid Clerk JWT in the `Authorization` header.
/// Returns 404 if the recipe doesn't belong to the authenticated user.
///
/// # Response
///
/// Returns a single `ResolvedRecipe` as JSON.
#[cfg(target_arch = "wasm32")]
pub async fn handle_get_recipe(
    req: worker::Request,
    ctx: worker::RouteContext<()>,
) -> worker::Result<worker::Response> {
    use crate::db::queries;
    use crate::middleware::{
        attach_correlation_header, authenticate_request, extract_request_context,
    };
    use crate::types::ids::UserId;

    let request_ctx = extract_request_context(&req);

    let recipe_id = match ctx.param("id") {
        Some(id) => id.to_string(),
        None => {
            flush_logs(&request_ctx, &ctx).await;
            let mut resp = error_response("missing_id", "Recipe ID is required", 400)?;
            attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
            return Ok(resp);
        }
    };

    request_ctx.logger.info(
        "Recipe detail requested",
        HashMap::from([
            (
                "path".to_string(),
                serde_json::Value::String(format!("/recipes/{recipe_id}")),
            ),
            (
                "recipe_id".to_string(),
                serde_json::Value::String(recipe_id.clone()),
            ),
        ]),
    );

    // Authenticate
    let jwks_url = ctx
        .var("CLERK_JWKS_URL")
        .map(|v| v.to_string())
        .unwrap_or_else(|_| "https://api.clerk.com/v1/jwks".to_string());

    let claims = match authenticate_request(&req, &request_ctx, &jwks_url).await {
        Ok(claims) => claims,
        Err(auth_error) => {
            flush_logs(&request_ctx, &ctx).await;
            let mut resp = auth_error.to_response()?;
            attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
            return Ok(resp);
        }
    };

    let user_id = UserId::new(&claims.sub);

    let db = ctx
        .env
        .d1("DB")
        .map_err(|e| worker::Error::RustError(format!("failed to get D1 binding: {e}")))?;

    let recipe = match queries::get_recipe_by_id(&db, &recipe_id, &user_id).await {
        Ok(r) => r,
        Err(crate::db::queries::DbError::NotFound { .. }) => {
            request_ctx.logger.info(
                "Recipe not found",
                HashMap::from([(
                    "recipe_id".to_string(),
                    serde_json::Value::String(recipe_id.clone()),
                )]),
            );
            flush_logs(&request_ctx, &ctx).await;
            let mut resp = error_response("not_found", "Recipe not found", 404)?;
            attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
            return Ok(resp);
        }
        Err(e) => {
            request_ctx.logger.error(
                "Failed to fetch recipe",
                HashMap::from([(
                    "error".to_string(),
                    serde_json::Value::String(e.to_string()),
                )]),
            );
            flush_logs(&request_ctx, &ctx).await;
            let mut resp =
                error_response("db_error", &format!("Failed to fetch recipe: {e}"), 500)?;
            attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
            return Ok(resp);
        }
    };

    flush_logs(&request_ctx, &ctx).await;

    let json =
        serde_json::to_string(&recipe).map_err(|e| worker::Error::RustError(e.to_string()))?;

    let mut resp = worker::Response::ok(json)?;
    let _ = resp.headers_mut().set("Content-Type", "application/json");
    attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
    Ok(resp)
}

/// Handles `GET /recipes/:id/nutrition` -- nutrition breakdown for a recipe.
///
/// Returns a detailed nutrition breakdown including per-recipe totals,
/// per-serving values, and per-ingredient nutrition where available.
///
/// # Authentication
///
/// Requires a valid Clerk JWT in the `Authorization` header.
/// Returns 404 if the recipe doesn't belong to the authenticated user.
///
/// # Response
///
/// Returns the `NutritionComputation` and ingredient-level nutrition as JSON.
#[cfg(target_arch = "wasm32")]
pub async fn handle_get_nutrition(
    req: worker::Request,
    ctx: worker::RouteContext<()>,
) -> worker::Result<worker::Response> {
    use crate::db::queries;
    use crate::middleware::{
        attach_correlation_header, authenticate_request, extract_request_context,
    };
    use crate::types::ids::UserId;

    let request_ctx = extract_request_context(&req);

    let recipe_id = match ctx.param("id") {
        Some(id) => id.to_string(),
        None => {
            flush_logs(&request_ctx, &ctx).await;
            let mut resp = error_response("missing_id", "Recipe ID is required", 400)?;
            attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
            return Ok(resp);
        }
    };

    request_ctx.logger.info(
        "Recipe nutrition requested",
        HashMap::from([
            (
                "path".to_string(),
                serde_json::Value::String(format!("/recipes/{recipe_id}/nutrition")),
            ),
            (
                "recipe_id".to_string(),
                serde_json::Value::String(recipe_id.clone()),
            ),
        ]),
    );

    // Authenticate
    let jwks_url = ctx
        .var("CLERK_JWKS_URL")
        .map(|v| v.to_string())
        .unwrap_or_else(|_| "https://api.clerk.com/v1/jwks".to_string());

    let claims = match authenticate_request(&req, &request_ctx, &jwks_url).await {
        Ok(claims) => claims,
        Err(auth_error) => {
            flush_logs(&request_ctx, &ctx).await;
            let mut resp = auth_error.to_response()?;
            attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
            return Ok(resp);
        }
    };

    let user_id = UserId::new(&claims.sub);

    let db = ctx
        .env
        .d1("DB")
        .map_err(|e| worker::Error::RustError(format!("failed to get D1 binding: {e}")))?;

    let recipe = match queries::get_recipe_by_id(&db, &recipe_id, &user_id).await {
        Ok(r) => r,
        Err(crate::db::queries::DbError::NotFound { .. }) => {
            flush_logs(&request_ctx, &ctx).await;
            let mut resp = error_response("not_found", "Recipe not found", 404)?;
            attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
            return Ok(resp);
        }
        Err(e) => {
            request_ctx.logger.error(
                "Failed to fetch recipe for nutrition",
                HashMap::from([(
                    "error".to_string(),
                    serde_json::Value::String(e.to_string()),
                )]),
            );
            flush_logs(&request_ctx, &ctx).await;
            let mut resp =
                error_response("db_error", &format!("Failed to fetch recipe: {e}"), 500)?;
            attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
            return Ok(resp);
        }
    };

    // Build the nutrition response with per-ingredient detail
    let nutrition_response = NutritionDetailResponse {
        recipe_id: recipe_id.clone(),
        nutrition: recipe.nutrition,
        ingredients: recipe
            .ingredients
            .into_iter()
            .map(|i| IngredientNutritionDetail {
                name: i.parsed.name,
                quantity: i.parsed.quantity,
                unit: i.parsed.unit,
                resolution_type: match &i.resolution {
                    crate::types::ingredient::IngredientResolution::Matched { .. } => {
                        "matched".to_string()
                    }
                    crate::types::ingredient::IngredientResolution::FuzzyMatched { .. } => {
                        "fuzzy_matched".to_string()
                    }
                    crate::types::ingredient::IngredientResolution::Unmatched { .. } => {
                        "unmatched".to_string()
                    }
                },
            })
            .collect(),
    };

    flush_logs(&request_ctx, &ctx).await;

    let json = serde_json::to_string(&nutrition_response)
        .map_err(|e| worker::Error::RustError(e.to_string()))?;

    let mut resp = worker::Response::ok(json)?;
    let _ = resp.headers_mut().set("Content-Type", "application/json");
    attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
    Ok(resp)
}

/// Response body for the nutrition detail endpoint.
#[cfg(target_arch = "wasm32")]
#[derive(Debug, Serialize)]
struct NutritionDetailResponse {
    /// The recipe ID.
    recipe_id: String,
    /// The overall nutrition computation.
    nutrition: crate::types::nutrition::NutritionComputation,
    /// Per-ingredient nutrition detail.
    ingredients: Vec<IngredientNutritionDetail>,
}

/// Per-ingredient detail in the nutrition response.
#[cfg(target_arch = "wasm32")]
#[derive(Debug, Serialize)]
struct IngredientNutritionDetail {
    /// The ingredient name.
    name: String,
    /// The ingredient quantity.
    quantity: Option<f64>,
    /// The ingredient unit.
    unit: Option<String>,
    /// The resolution type (matched/fuzzy_matched/unmatched).
    resolution_type: String,
}

/// Builds a JSON error response with the given code, message, and HTTP status.
#[cfg(target_arch = "wasm32")]
fn error_response(code: &str, message: &str, status: u16) -> worker::Result<worker::Response> {
    let body = RecipeErrorResponse {
        error: RecipeErrorDetail {
            code: code.to_string(),
            message: message.to_string(),
        },
    };
    let json = serde_json::to_string(&body).map_err(|e| worker::Error::RustError(e.to_string()))?;
    let mut resp = worker::Response::ok(json)?;
    let _ = resp.headers_mut().set("Content-Type", "application/json");
    Ok(resp.with_status(status))
}

/// Best-effort flush of buffered logs to Axiom.
#[cfg(target_arch = "wasm32")]
async fn flush_logs(
    request_ctx: &crate::middleware::RequestContext,
    ctx: &worker::RouteContext<()>,
) {
    let axiom_token = ctx
        .secret("AXIOM_API_TOKEN")
        .map(|s| s.to_string())
        .unwrap_or_default();
    let axiom_dataset = ctx
        .var("AXIOM_DATASET")
        .map(|v| v.to_string())
        .unwrap_or_else(|_| "dishy-api".to_string());

    if !axiom_token.is_empty() {
        let _ = request_ctx.logger.flush(&axiom_token, &axiom_dataset).await;
    }
}

/// Handles async capture for social_link and screenshot input types.
///
/// Creates the capture input in D1, enqueues a message on the capture queue,
/// and returns 202 Accepted with the capture ID for polling.
#[cfg(target_arch = "wasm32")]
async fn handle_async_capture(
    capture_req: CaptureRequest,
    user_id: &crate::types::ids::UserId,
    request_ctx: &crate::middleware::RequestContext,
    ctx: &worker::RouteContext<()>,
) -> worker::Result<worker::Response> {
    use crate::db::queries;
    use crate::middleware::attach_correlation_header;
    use crate::pipeline::queue::CaptureQueueMessage;
    use crate::types::capture::CaptureInput;
    use crate::types::ids::{AssetId, CaptureId};

    let db = ctx
        .env
        .d1("DB")
        .map_err(|e| worker::Error::RustError(format!("failed to get D1 binding: {e}")))?;

    let capture_id = CaptureId::new(uuid::Uuid::new_v4().to_string());

    // Build the capture input based on type
    let capture_input = match capture_req.input_type.as_str() {
        "social_link" => {
            if capture_req.url.trim().is_empty() {
                flush_logs(request_ctx, ctx).await;
                let mut resp = error_response(
                    "empty_url",
                    "URL cannot be empty for social_link capture",
                    400,
                )?;
                attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
                return Ok(resp);
            }
            CaptureInput::SocialLink {
                url: capture_req.url.clone(),
            }
        }
        "screenshot" => {
            if capture_req.image_data.trim().is_empty() {
                flush_logs(request_ctx, ctx).await;
                let mut resp = error_response(
                    "empty_image",
                    "image_data cannot be empty for screenshot capture",
                    400,
                )?;
                attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
                return Ok(resp);
            }

            // Decode base64 and upload to R2
            let image_bytes = base64::Engine::decode(
                &base64::engine::general_purpose::STANDARD,
                &capture_req.image_data,
            )
            .map_err(|e| worker::Error::RustError(format!("invalid base64 image data: {e}")))?;

            let ct = if capture_req.content_type.is_empty() {
                "image/jpeg".to_string()
            } else {
                capture_req.content_type.clone()
            };

            let bucket = ctx
                .env
                .bucket("IMAGES")
                .map_err(|e| worker::Error::RustError(format!("failed to get R2 bucket: {e}")))?;

            let upload_result = crate::services::storage::upload_image(
                &bucket,
                &image_bytes,
                &ct,
                &request_ctx.logger,
            )
            .await
            .map_err(|e| worker::Error::RustError(format!("failed to upload screenshot: {e}")))?;

            CaptureInput::Screenshot {
                image: upload_result.asset_id,
            }
        }
        _ => {
            flush_logs(request_ctx, ctx).await;
            let mut resp = error_response("invalid_type", "Invalid async capture type", 400)?;
            attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
            return Ok(resp);
        }
    };

    // Save capture input to D1
    if let Err(e) = queries::insert_capture_input(&db, &capture_id, user_id, &capture_input).await {
        request_ctx.logger.error(
            "Failed to save async capture input",
            HashMap::from([(
                "error".to_string(),
                serde_json::Value::String(e.to_string()),
            )]),
        );
        flush_logs(request_ctx, ctx).await;
        let mut resp = error_response("db_error", &format!("Failed to save capture: {e}"), 500)?;
        attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
        return Ok(resp);
    }

    // Enqueue the message
    let queue = ctx
        .env
        .queue("CAPTURE_QUEUE")
        .map_err(|e| worker::Error::RustError(format!("failed to get queue binding: {e}")))?;

    let queue_msg = CaptureQueueMessage {
        capture_id: capture_id.as_str().to_string(),
        user_id: user_id.as_str().to_string(),
    };

    queue
        .send(serde_json::to_value(&queue_msg).map_err(|e| {
            worker::Error::RustError(format!("failed to serialize queue message: {e}"))
        })?)
        .await
        .map_err(|e| worker::Error::RustError(format!("failed to enqueue message: {e}")))?;

    request_ctx.logger.info(
        "Async capture enqueued",
        HashMap::from([
            (
                "capture_id".to_string(),
                serde_json::Value::String(capture_id.as_str().to_string()),
            ),
            (
                "input_type".to_string(),
                serde_json::Value::String(capture_req.input_type.clone()),
            ),
        ]),
    );

    flush_logs(request_ctx, ctx).await;

    let body = AsyncCaptureResponse {
        capture_id: capture_id.as_str().to_string(),
        status: "received".to_string(),
        message: "Capture submitted for processing. Poll GET /captures/<id> for status."
            .to_string(),
    };

    let json = serde_json::to_string(&body).map_err(|e| worker::Error::RustError(e.to_string()))?;

    let mut resp = worker::Response::ok(json)?;
    let _ = resp.headers_mut().set("Content-Type", "application/json");
    attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
    Ok(resp.with_status(202))
}

/// Handles `GET /captures/:id` -- poll capture status.
///
/// Returns the current pipeline state, error message (if failed),
/// and recipe ID (if resolved).
///
/// # Authentication
///
/// Requires a valid Clerk JWT. Returns 404 if the capture doesn't
/// belong to the authenticated user.
#[cfg(target_arch = "wasm32")]
pub async fn handle_get_capture_status(
    req: worker::Request,
    ctx: worker::RouteContext<()>,
) -> worker::Result<worker::Response> {
    use crate::middleware::{
        attach_correlation_header, authenticate_request, extract_request_context,
    };
    use worker::wasm_bindgen::JsValue;

    let request_ctx = extract_request_context(&req);

    let capture_id = match ctx.param("id") {
        Some(id) => id.to_string(),
        None => {
            flush_logs(&request_ctx, &ctx).await;
            let mut resp = error_response("missing_id", "Capture ID is required", 400)?;
            attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
            return Ok(resp);
        }
    };

    // Authenticate
    let jwks_url = ctx
        .var("CLERK_JWKS_URL")
        .map(|v| v.to_string())
        .unwrap_or_else(|_| "https://api.clerk.com/v1/jwks".to_string());

    let claims = match authenticate_request(&req, &request_ctx, &jwks_url).await {
        Ok(claims) => claims,
        Err(auth_error) => {
            flush_logs(&request_ctx, &ctx).await;
            let mut resp = auth_error.to_response()?;
            attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
            return Ok(resp);
        }
    };

    let db = ctx
        .env
        .d1("DB")
        .map_err(|e| worker::Error::RustError(format!("failed to get D1 binding: {e}")))?;

    let statement = db.prepare(
        "SELECT id, pipeline_state, error_message, recipe_id FROM capture_inputs WHERE id = ?1 AND user_id = ?2",
    );

    let result = statement
        .bind(&[
            JsValue::from_str(&capture_id),
            JsValue::from_str(&claims.sub),
        ])
        .map_err(|e| worker::Error::RustError(format!("bind failed: {e}")))?
        .all()
        .await
        .map_err(|e| worker::Error::RustError(format!("query failed: {e}")))?;

    let rows = result
        .results::<serde_json::Value>()
        .map_err(|e| worker::Error::RustError(format!("results parse failed: {e}")))?;

    let row = match rows.into_iter().next() {
        Some(r) => r,
        None => {
            flush_logs(&request_ctx, &ctx).await;
            let mut resp = error_response("not_found", "Capture not found", 404)?;
            attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
            return Ok(resp);
        }
    };

    let body = CaptureStatusResponse {
        capture_id: row["id"].as_str().unwrap_or_default().to_string(),
        status: row["pipeline_state"]
            .as_str()
            .unwrap_or("unknown")
            .to_string(),
        error_message: row["error_message"].as_str().map(String::from),
        recipe_id: row["recipe_id"].as_str().map(String::from),
    };

    flush_logs(&request_ctx, &ctx).await;

    let json = serde_json::to_string(&body).map_err(|e| worker::Error::RustError(e.to_string()))?;

    let mut resp = worker::Response::ok(json)?;
    let _ = resp.headers_mut().set("Content-Type", "application/json");
    attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
    Ok(resp)
}

// Non-WASM stubs for compilation on the host target (used in `cargo test`).
// The Worker runtime (Router, D1, Fetch) is not available outside wasm32,
// so these stubs allow the crate to compile and run unit tests on the host.

/// Stub for `handle_capture` on non-WASM targets.
#[cfg(not(target_arch = "wasm32"))]
pub async fn handle_capture(
    req: worker::Request,
    ctx: worker::RouteContext<()>,
) -> worker::Result<worker::Response> {
    let _ = (req, ctx);
    worker::Response::error("Not available outside WASM runtime", 501)
}

/// Stub for `handle_list_recipes` on non-WASM targets.
#[cfg(not(target_arch = "wasm32"))]
pub async fn handle_list_recipes(
    req: worker::Request,
    ctx: worker::RouteContext<()>,
) -> worker::Result<worker::Response> {
    let _ = (req, ctx);
    worker::Response::error("Not available outside WASM runtime", 501)
}

/// Stub for `handle_get_recipe` on non-WASM targets.
#[cfg(not(target_arch = "wasm32"))]
pub async fn handle_get_recipe(
    req: worker::Request,
    ctx: worker::RouteContext<()>,
) -> worker::Result<worker::Response> {
    let _ = (req, ctx);
    worker::Response::error("Not available outside WASM runtime", 501)
}

/// Stub for `handle_get_nutrition` on non-WASM targets.
#[cfg(not(target_arch = "wasm32"))]
pub async fn handle_get_nutrition(
    req: worker::Request,
    ctx: worker::RouteContext<()>,
) -> worker::Result<worker::Response> {
    let _ = (req, ctx);
    worker::Response::error("Not available outside WASM runtime", 501)
}

/// Stub for `handle_get_capture_status` on non-WASM targets.
#[cfg(not(target_arch = "wasm32"))]
pub async fn handle_get_capture_status(
    req: worker::Request,
    ctx: worker::RouteContext<()>,
) -> worker::Result<worker::Response> {
    let _ = (req, ctx);
    worker::Response::error("Not available outside WASM runtime", 501)
}
