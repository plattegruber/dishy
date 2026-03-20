//! Recipe capture and retrieval route handlers.
//!
//! Implements the three recipe endpoints:
//! - `POST /recipes/capture` -- manual text capture with Claude extraction
//! - `GET /recipes` -- list all recipes for the authenticated user
//! - `GET /recipes/:id` -- get a single recipe by ID
//!
//! All endpoints require authentication via Clerk JWT.

#[cfg(target_arch = "wasm32")]
use std::collections::HashMap;

#[cfg(target_arch = "wasm32")]
use serde::{Deserialize, Serialize};

/// Request body for the manual capture endpoint.
#[cfg(target_arch = "wasm32")]
#[derive(Debug, Deserialize)]
pub struct CaptureRequest {
    /// The type of input (only "manual" is supported in Phase 4).
    pub input_type: String,
    /// The raw recipe text to extract from.
    pub text: String,
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
    if capture_req.input_type != "manual" {
        flush_logs(&request_ctx, &ctx).await;
        let mut resp = error_response(
            "unsupported_input_type",
            &format!(
                "Unsupported input type: {}. Only 'manual' is supported.",
                capture_req.input_type
            ),
            400,
        )?;
        attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
        return Ok(resp);
    }

    // Validate text is not empty
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

    // Parse and resolve ingredients (stub stages)
    let ingredient_lines = parse_ingredients(&candidate).await;
    let resolved_ingredients = resolve_ingredients(&ingredient_lines).await;

    // Compute nutrition (stub)
    let nutrition = compute_nutrition(&resolved_ingredients).await;

    // Generate cover (stub)
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
