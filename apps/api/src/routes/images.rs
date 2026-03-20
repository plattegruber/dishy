//! Image upload and serving route handlers.
//!
//! Implements two endpoints for image handling:
//! - `POST /recipes/:id/cover` -- upload a cover image for a recipe
//! - `GET /images/:asset_id` -- serve an image from R2
//!
//! The upload endpoint requires authentication (Clerk JWT). The serving
//! endpoint is public and sets appropriate cache headers for CDN.

#[cfg(target_arch = "wasm32")]
use std::collections::HashMap;

#[cfg(target_arch = "wasm32")]
use serde::Serialize;

/// Error response body for image endpoints.
#[cfg(target_arch = "wasm32")]
#[derive(Debug, Serialize)]
struct ImageErrorResponse {
    /// Nested error object.
    error: ImageErrorDetail,
}

/// Inner error detail for image endpoint errors.
#[cfg(target_arch = "wasm32")]
#[derive(Debug, Serialize)]
struct ImageErrorDetail {
    /// Machine-readable error code.
    code: String,
    /// Human-readable error message.
    message: String,
}

/// Handles `POST /recipes/:id/cover` -- upload a cover image for a recipe.
///
/// Accepts a raw binary body (the image bytes) with a `Content-Type`
/// header indicating the image format. Validates the image, uploads
/// it to R2, and updates the recipe's cover in D1.
///
/// # Authentication
///
/// Requires a valid Clerk JWT in the `Authorization` header.
///
/// # Request
///
/// - Body: raw image bytes
/// - Content-Type: `image/jpeg`, `image/png`, or `image/webp`
/// - Max size: 10 MB
///
/// # Response
///
/// Returns the updated cover output as JSON with status 200.
#[cfg(target_arch = "wasm32")]
pub async fn handle_upload_cover(
    mut req: worker::Request,
    ctx: worker::RouteContext<()>,
) -> worker::Result<worker::Response> {
    use crate::middleware::{
        attach_correlation_header, authenticate_request, extract_request_context,
    };
    use crate::services::storage;
    use crate::types::ids::UserId;
    use crate::types::recipe::CoverOutput;

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
        "Cover upload requested",
        HashMap::from([
            (
                "path".to_string(),
                serde_json::Value::String(format!("/recipes/{recipe_id}/cover")),
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

    // Verify the recipe belongs to this user
    let db = ctx
        .env
        .d1("DB")
        .map_err(|e| worker::Error::RustError(format!("failed to get D1 binding: {e}")))?;

    if let Err(e) = crate::db::queries::get_recipe_by_id(&db, &recipe_id, &user_id).await {
        request_ctx.logger.warn(
            "Recipe not found for cover upload",
            HashMap::from([
                (
                    "recipe_id".to_string(),
                    serde_json::Value::String(recipe_id.clone()),
                ),
                (
                    "error".to_string(),
                    serde_json::Value::String(e.to_string()),
                ),
            ]),
        );
        flush_logs(&request_ctx, &ctx).await;
        let mut resp = error_response("not_found", "Recipe not found", 404)?;
        attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
        return Ok(resp);
    }

    // Read content type
    let content_type = req
        .headers()
        .get("Content-Type")
        .ok()
        .flatten()
        .unwrap_or_default();

    if !storage::is_supported_content_type(&content_type) {
        flush_logs(&request_ctx, &ctx).await;
        let mut resp = error_response(
            "unsupported_content_type",
            &format!(
                "Unsupported image type: {content_type}. Supported: image/jpeg, image/png, image/webp"
            ),
            400,
        )?;
        attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
        return Ok(resp);
    }

    // Read the body bytes
    let body_bytes = req
        .bytes()
        .await
        .map_err(|e| worker::Error::RustError(format!("failed to read request body: {e}")))?;

    // Validate size
    if let Err(e) = storage::validate_image(&body_bytes, &content_type) {
        request_ctx.logger.warn(
            "Image validation failed",
            HashMap::from([(
                "error".to_string(),
                serde_json::Value::String(e.to_string()),
            )]),
        );
        flush_logs(&request_ctx, &ctx).await;
        let mut resp = error_response("validation_failed", &e.to_string(), 400)?;
        attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
        return Ok(resp);
    }

    // Upload to R2
    let bucket = ctx
        .env
        .bucket("IMAGES")
        .map_err(|e| worker::Error::RustError(format!("failed to get R2 binding: {e}")))?;

    let asset_id = match storage::upload_image(&bucket, &body_bytes, &content_type, "cover").await {
        Ok(id) => id,
        Err(e) => {
            request_ctx.logger.error(
                "R2 upload failed",
                HashMap::from([(
                    "error".to_string(),
                    serde_json::Value::String(e.to_string()),
                )]),
            );
            flush_logs(&request_ctx, &ctx).await;
            let mut resp =
                error_response("upload_failed", &format!("Image upload failed: {e}"), 500)?;
            attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
            return Ok(resp);
        }
    };

    // Update the recipe cover in D1
    let cover = CoverOutput::SourceImage {
        asset_id: asset_id.clone(),
    };
    let cover_json = serde_json::to_string(&cover)
        .map_err(|e| worker::Error::RustError(format!("failed to serialize cover: {e}")))?;

    if let Err(e) = update_recipe_cover(&db, &recipe_id, &cover_json).await {
        request_ctx.logger.error(
            "Failed to update recipe cover in D1",
            HashMap::from([(
                "error".to_string(),
                serde_json::Value::String(e.to_string()),
            )]),
        );
        flush_logs(&request_ctx, &ctx).await;
        let mut resp = error_response("db_error", &format!("Failed to update cover: {e}"), 500)?;
        attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
        return Ok(resp);
    }

    request_ctx.logger.info(
        "Cover uploaded successfully",
        HashMap::from([
            (
                "recipe_id".to_string(),
                serde_json::Value::String(recipe_id),
            ),
            (
                "asset_id".to_string(),
                serde_json::Value::String(asset_id.as_str().to_string()),
            ),
        ]),
    );

    flush_logs(&request_ctx, &ctx).await;

    let json =
        serde_json::to_string(&cover).map_err(|e| worker::Error::RustError(e.to_string()))?;

    let mut resp = worker::Response::ok(json)?;
    let _ = resp.headers_mut().set("Content-Type", "application/json");
    attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
    Ok(resp)
}

/// Handles `GET /images/:asset_id` -- serve an image from R2.
///
/// Retrieves the image from the R2 bucket and returns it with the
/// correct Content-Type header and cache headers for CDN caching.
///
/// # Response Headers
///
/// - `Content-Type`: matches the stored image format
/// - `Cache-Control`: `public, max-age=31536000, immutable` (1 year)
///
/// This endpoint is **public** -- no authentication required.
#[cfg(target_arch = "wasm32")]
pub async fn handle_get_image(
    req: worker::Request,
    ctx: worker::RouteContext<()>,
) -> worker::Result<worker::Response> {
    use crate::middleware::{attach_correlation_header, extract_request_context};
    use crate::services::storage;

    let request_ctx = extract_request_context(&req);

    let asset_id = match ctx.param("asset_id") {
        Some(id) => id.to_string(),
        None => {
            flush_logs(&request_ctx, &ctx).await;
            let mut resp = error_response("missing_asset_id", "Asset ID is required", 400)?;
            attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
            return Ok(resp);
        }
    };

    request_ctx.logger.debug(
        "Image requested",
        HashMap::from([(
            "asset_id".to_string(),
            serde_json::Value::String(asset_id.clone()),
        )]),
    );

    let bucket = ctx
        .env
        .bucket("IMAGES")
        .map_err(|e| worker::Error::RustError(format!("failed to get R2 binding: {e}")))?;

    let (bytes, content_type) = match storage::get_image(&bucket, &asset_id).await {
        Ok(result) => result,
        Err(e) => {
            request_ctx.logger.warn(
                "Image not found",
                HashMap::from([
                    (
                        "asset_id".to_string(),
                        serde_json::Value::String(asset_id.clone()),
                    ),
                    (
                        "error".to_string(),
                        serde_json::Value::String(e.to_string()),
                    ),
                ]),
            );
            flush_logs(&request_ctx, &ctx).await;
            let mut resp = error_response("not_found", "Image not found", 404)?;
            attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
            return Ok(resp);
        }
    };

    flush_logs(&request_ctx, &ctx).await;

    let mut resp = worker::Response::from_bytes(bytes)?;
    let _ = resp.headers_mut().set("Content-Type", &content_type);
    let _ = resp
        .headers_mut()
        .set("Cache-Control", "public, max-age=31536000, immutable");
    attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
    Ok(resp)
}

/// Updates the cover_json column for a recipe in D1.
#[cfg(target_arch = "wasm32")]
async fn update_recipe_cover(
    db: &worker::d1::D1Database,
    recipe_id: &str,
    cover_json: &str,
) -> Result<(), crate::db::queries::DbError> {
    use crate::db::queries::DbError;
    use worker::wasm_bindgen::JsValue;

    let now = chrono::Utc::now().to_rfc3339();

    let statement = db.prepare("UPDATE recipes SET cover_json = ?1, updated_at = ?2 WHERE id = ?3");

    statement
        .bind(&[
            JsValue::from_str(cover_json),
            JsValue::from_str(&now),
            JsValue::from_str(recipe_id),
        ])
        .map_err(|e| DbError::QueryFailed(format!("bind failed: {e}")))?
        .run()
        .await
        .map_err(|e| DbError::QueryFailed(format!("run failed: {e}")))?;

    Ok(())
}

/// Builds a JSON error response with the given code, message, and HTTP status.
#[cfg(target_arch = "wasm32")]
fn error_response(code: &str, message: &str, status: u16) -> worker::Result<worker::Response> {
    let body = ImageErrorResponse {
        error: ImageErrorDetail {
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

/// Stub for `handle_upload_cover` on non-WASM targets.
#[cfg(not(target_arch = "wasm32"))]
pub async fn handle_upload_cover(
    req: worker::Request,
    ctx: worker::RouteContext<()>,
) -> worker::Result<worker::Response> {
    let _ = (req, ctx);
    worker::Response::error("Not available outside WASM runtime", 501)
}

/// Stub for `handle_get_image` on non-WASM targets.
#[cfg(not(target_arch = "wasm32"))]
pub async fn handle_get_image(
    req: worker::Request,
    ctx: worker::RouteContext<()>,
) -> worker::Result<worker::Response> {
    let _ = (req, ctx);
    worker::Response::error("Not available outside WASM runtime", 501)
}
