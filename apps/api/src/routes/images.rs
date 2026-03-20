//! Image serving and upload route handlers.
//!
//! Implements:
//! - `GET /images/:asset_id` -- serve images from R2 with cache headers
//! - `POST /recipes/:id/cover` -- upload a cover image for a recipe
//!
//! The image serving endpoint is **unauthenticated** so images can be
//! served directly to `<img>` tags without token injection. The upload
//! endpoint requires authentication.

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

/// Handles `GET /images/:asset_id` -- serve an image from R2.
///
/// Looks up the image in the R2 bucket by asset ID, returning the raw
/// image bytes with appropriate `Content-Type` and `Cache-Control`
/// headers. Images are cached for 1 year since asset IDs are immutable.
///
/// This endpoint is **unauthenticated** so images can be loaded in
/// `<img>` tags directly.
///
/// # Response
///
/// Returns the raw image bytes with the image's Content-Type header.
/// Returns 404 if the image is not found.
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
            return image_error_response("missing_asset_id", "Asset ID is required", 400);
        }
    };

    request_ctx.logger.info(
        "Image requested",
        HashMap::from([
            (
                "path".to_string(),
                serde_json::Value::String(format!("/images/{asset_id}")),
            ),
            (
                "asset_id".to_string(),
                serde_json::Value::String(asset_id.clone()),
            ),
        ]),
    );

    let bucket = match ctx.env.bucket("IMAGES") {
        Ok(b) => b,
        Err(e) => {
            request_ctx.logger.error(
                "IMAGES R2 bucket not available",
                HashMap::from([(
                    "error".to_string(),
                    serde_json::Value::String(e.to_string()),
                )]),
            );
            flush_logs(&request_ctx, &ctx).await;
            return image_error_response(
                "storage_unavailable",
                "Image storage is not available",
                503,
            );
        }
    };

    match storage::retrieve_image(&bucket, &asset_id, &request_ctx.logger).await {
        Ok(result) => {
            flush_logs(&request_ctx, &ctx).await;

            let mut resp = worker::Response::from_bytes(result.data)?;
            let headers = resp.headers_mut();
            let _ = headers.set("Content-Type", &result.content_type);
            // Cache immutable assets for 1 year
            let _ = headers.set("Cache-Control", "public, max-age=31536000, immutable");
            attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
            Ok(resp)
        }
        Err(storage::StorageError::NotFound { .. }) => {
            request_ctx.logger.info(
                "Image not found",
                HashMap::from([("asset_id".to_string(), serde_json::Value::String(asset_id))]),
            );
            flush_logs(&request_ctx, &ctx).await;
            image_error_response("not_found", "Image not found", 404)
        }
        Err(e) => {
            request_ctx.logger.error(
                "Failed to retrieve image",
                HashMap::from([(
                    "error".to_string(),
                    serde_json::Value::String(e.to_string()),
                )]),
            );
            flush_logs(&request_ctx, &ctx).await;
            image_error_response(
                "storage_error",
                &format!("Failed to retrieve image: {e}"),
                500,
            )
        }
    }
}

/// Handles `POST /recipes/:id/cover` -- upload a cover image.
///
/// Accepts a multipart form upload with an image file, validates the
/// content type and size, uploads to R2, and updates the recipe's
/// cover output. Requires authentication.
///
/// # Authentication
///
/// Requires a valid Clerk JWT in the `Authorization` header.
///
/// # Request
///
/// Multipart form data with a field named `image` containing the image file.
///
/// # Response
///
/// Returns the new `CoverOutput` as JSON with status 200.
#[cfg(target_arch = "wasm32")]
pub async fn handle_upload_cover(
    mut req: worker::Request,
    ctx: worker::RouteContext<()>,
) -> worker::Result<worker::Response> {
    use crate::db::queries;
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
            let mut resp = image_error_response("missing_id", "Recipe ID is required", 400)?;
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

    // Verify the recipe exists and belongs to this user
    let db = ctx
        .env
        .d1("DB")
        .map_err(|e| worker::Error::RustError(format!("failed to get D1 binding: {e}")))?;

    match queries::get_recipe_by_id(&db, &recipe_id, &user_id).await {
        Ok(_) => {} // Recipe exists and belongs to user
        Err(crate::db::queries::DbError::NotFound { .. }) => {
            flush_logs(&request_ctx, &ctx).await;
            let mut resp = image_error_response("not_found", "Recipe not found", 404)?;
            attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
            return Ok(resp);
        }
        Err(e) => {
            flush_logs(&request_ctx, &ctx).await;
            let mut resp =
                image_error_response("db_error", &format!("Failed to verify recipe: {e}"), 500)?;
            attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
            return Ok(resp);
        }
    }

    // Read the request body as bytes
    let body_bytes = req
        .bytes()
        .await
        .map_err(|e| worker::Error::RustError(format!("failed to read request body: {e}")))?;

    // Get content type from header
    let content_type = req
        .headers()
        .get("Content-Type")
        .ok()
        .flatten()
        .unwrap_or_else(|| "application/octet-stream".to_string());

    // Validate content type
    if let Err(e) = storage::validate_content_type(&content_type) {
        request_ctx.logger.warn(
            "Invalid image content type for cover upload",
            HashMap::from([(
                "content_type".to_string(),
                serde_json::Value::String(content_type),
            )]),
        );
        flush_logs(&request_ctx, &ctx).await;
        let mut resp = image_error_response("invalid_image", &e.to_string(), 400)?;
        attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
        return Ok(resp);
    }

    // Validate size
    if let Err(e) = storage::validate_image_size(&body_bytes) {
        flush_logs(&request_ctx, &ctx).await;
        let mut resp = image_error_response("image_too_large", &e.to_string(), 413)?;
        attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
        return Ok(resp);
    }

    // Get R2 bucket
    let bucket = match ctx.env.bucket("IMAGES") {
        Ok(b) => b,
        Err(e) => {
            request_ctx.logger.error(
                "IMAGES R2 bucket not available",
                HashMap::from([(
                    "error".to_string(),
                    serde_json::Value::String(e.to_string()),
                )]),
            );
            flush_logs(&request_ctx, &ctx).await;
            let mut resp =
                image_error_response("storage_unavailable", "Image storage is not available", 503)?;
            attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
            return Ok(resp);
        }
    };

    // Upload the image
    let upload_result =
        match storage::upload_image(&bucket, &body_bytes, &content_type, &request_ctx.logger).await
        {
            Ok(result) => result,
            Err(e) => {
                request_ctx.logger.error(
                    "Failed to upload cover image",
                    HashMap::from([(
                        "error".to_string(),
                        serde_json::Value::String(e.to_string()),
                    )]),
                );
                flush_logs(&request_ctx, &ctx).await;
                let mut resp = image_error_response(
                    "upload_failed",
                    &format!("Failed to upload image: {e}"),
                    500,
                )?;
                attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
                return Ok(resp);
            }
        };

    let cover = CoverOutput::SourceImage {
        asset_id: upload_result.asset_id,
    };

    // Update the recipe's cover in D1
    if let Err(e) = queries::update_recipe_cover(&db, &recipe_id, &cover).await {
        request_ctx.logger.error(
            "Failed to update recipe cover in D1",
            HashMap::from([(
                "error".to_string(),
                serde_json::Value::String(e.to_string()),
            )]),
        );
        // Note: the image was uploaded successfully, so we still return it
        // The D1 update failure is logged but not fatal
    }

    request_ctx.logger.info(
        "Cover image uploaded successfully",
        HashMap::from([(
            "recipe_id".to_string(),
            serde_json::Value::String(recipe_id),
        )]),
    );

    flush_logs(&request_ctx, &ctx).await;

    let json =
        serde_json::to_string(&cover).map_err(|e| worker::Error::RustError(e.to_string()))?;

    let mut resp = worker::Response::ok(json)?;
    let _ = resp.headers_mut().set("Content-Type", "application/json");
    attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;
    Ok(resp)
}

/// Builds a JSON error response for image endpoints.
#[cfg(target_arch = "wasm32")]
fn image_error_response(
    code: &str,
    message: &str,
    status: u16,
) -> worker::Result<worker::Response> {
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

/// Stub for `handle_get_image` on non-WASM targets.
#[cfg(not(target_arch = "wasm32"))]
pub async fn handle_get_image(
    req: worker::Request,
    ctx: worker::RouteContext<()>,
) -> worker::Result<worker::Response> {
    let _ = (req, ctx);
    worker::Response::error("Not available outside WASM runtime", 501)
}

/// Stub for `handle_upload_cover` on non-WASM targets.
#[cfg(not(target_arch = "wasm32"))]
pub async fn handle_upload_cover(
    req: worker::Request,
    ctx: worker::RouteContext<()>,
) -> worker::Result<worker::Response> {
    let _ = (req, ctx);
    worker::Response::error("Not available outside WASM runtime", 501)
}
