//! Dishy API -- Cloudflare Worker entry point.
//!
//! This module sets up the Worker router and defines the available HTTP routes,
//! plus a queue consumer for async capture processing (social links, screenshots).
//!
//! Serves a health check endpoint (unauthenticated), an authenticated `/me`
//! endpoint, recipe CRUD endpoints (authenticated via Clerk JWT), and a capture
//! status polling endpoint. All requests are wrapped with correlation ID
//! middleware for cross-service observability via Axiom.

pub mod auth;
pub mod db;
pub mod errors;
pub mod logging;
pub mod middleware;
pub mod pipeline;
pub mod routes;
pub mod services;
pub mod types;

use std::collections::HashMap;

use serde::Serialize;
use worker::{event, Context, Env, Request, Response, Router};

#[cfg(target_arch = "wasm32")]
use worker::MessageExt;

use crate::middleware::{attach_correlation_header, authenticate_request, extract_request_context};

/// Response payload for the health check endpoint.
#[derive(Serialize)]
struct HealthResponse {
    /// Operational status of the API.
    status: &'static str,
    /// Current version of the API, matching Cargo.toml.
    version: &'static str,
}

/// Response payload for the authenticated `/me` endpoint.
#[derive(Serialize)]
struct MeResponse {
    /// Clerk user ID.
    user_id: String,
    /// User's primary email address, if available.
    email: Option<String>,
    /// Unix timestamp when the token was issued.
    token_issued_at: i64,
    /// Unix timestamp when the token expires.
    token_expires_at: i64,
}

/// Main fetch handler for all incoming HTTP requests.
///
/// Routes requests through the Worker router to the appropriate handler.
/// Returns a 404 for any unmatched routes.
#[event(fetch)]
async fn fetch(req: Request, env: Env, _ctx: Context) -> worker::Result<Response> {
    console_error_panic_hook::set_once();

    let router = Router::new();

    router
        .get_async("/health", |req, route_ctx| async move {
            handle_health(req, route_ctx).await
        })
        .get_async("/me", |req, route_ctx| async move {
            handle_me(req, route_ctx).await
        })
        .post_async("/recipes/capture", |req, route_ctx| async move {
            crate::routes::recipes::handle_capture(req, route_ctx).await
        })
        .get_async("/recipes", |req, route_ctx| async move {
            crate::routes::recipes::handle_list_recipes(req, route_ctx).await
        })
        .get_async("/recipes/:id", |req, route_ctx| async move {
            crate::routes::recipes::handle_get_recipe(req, route_ctx).await
        })
        .get_async("/recipes/:id/nutrition", |req, route_ctx| async move {
            crate::routes::recipes::handle_get_nutrition(req, route_ctx).await
        })
        .post_async("/recipes/:id/cover", |req, route_ctx| async move {
            crate::routes::images::handle_upload_cover(req, route_ctx).await
        })
        .get_async("/images/:asset_id", |req, route_ctx| async move {
            crate::routes::images::handle_get_image(req, route_ctx).await
        })
        .get_async("/captures/:id", |req, route_ctx| async move {
            crate::routes::recipes::handle_get_capture_status(req, route_ctx).await
        })
        .run(req, env)
        .await
}

/// Queue consumer for async capture processing.
///
/// Processes social link and screenshot captures that were enqueued
/// by the `POST /recipes/capture` endpoint. Each message contains a
/// capture ID referencing a row in the `capture_inputs` D1 table.
///
/// Uses the `MessageExt` trait for `.ack()` on each message.
#[cfg(target_arch = "wasm32")]
#[event(queue)]
async fn queue(
    message_batch: worker::MessageBatch<serde_json::Value>,
    env: Env,
    _ctx: Context,
) -> worker::Result<()> {
    use crate::pipeline::queue::{mark_capture_failed, process_capture, CaptureQueueMessage};

    let messages = message_batch.messages()?;

    for msg in messages {
        let body = msg.body();

        let queue_msg: CaptureQueueMessage = match serde_json::from_value(body.clone()) {
            Ok(m) => m,
            Err(e) => {
                worker::console_log!(
                    "[queue] Failed to deserialize queue message: {e}. Acking to prevent retry."
                );
                msg.ack();
                continue;
            }
        };

        match process_capture(&queue_msg, &env).await {
            Ok(()) => {
                worker::console_log!(
                    "[queue] Successfully processed capture: {}",
                    queue_msg.capture_id
                );
                msg.ack();
            }
            Err(err_msg) => {
                worker::console_log!(
                    "[queue] Failed to process capture {}: {}",
                    queue_msg.capture_id,
                    err_msg
                );

                // Mark the capture as failed in D1
                if let Ok(db) = env.d1("DB") {
                    let _ = mark_capture_failed(&db, &queue_msg.capture_id, &err_msg).await;
                }

                // Ack the message so it goes to DLQ after max retries
                msg.ack();
            }
        }
    }

    Ok(())
}

/// Handles GET /health requests.
///
/// Returns a JSON payload with the API status and version number.
/// Uses structured logging with correlation ID context and flushes
/// logs to Axiom at the end of the request. Used by monitoring systems
/// and CI/CD to verify the Worker is operational.
///
/// This endpoint is **unauthenticated** -- no Bearer token required.
async fn handle_health(req: Request, ctx: worker::RouteContext<()>) -> worker::Result<Response> {
    let request_ctx = extract_request_context(&req);

    request_ctx.logger.info(
        "Health check requested",
        HashMap::from([(
            "path".to_string(),
            serde_json::Value::String("/health".to_string()),
        )]),
    );

    let body = HealthResponse {
        status: "ok",
        version: env!("CARGO_PKG_VERSION"),
    };

    let json = serde_json::to_string(&body).map_err(|e| worker::Error::RustError(e.to_string()))?;

    // Attempt to flush logs to Axiom (best-effort)
    flush_logs(&request_ctx, &ctx).await;

    let mut resp = Response::ok(json)?;
    let _ = resp.headers_mut().set("Content-Type", "application/json");
    attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;

    Ok(resp)
}

/// Handles GET /me requests.
///
/// Authenticates the request using the Bearer JWT from the `Authorization`
/// header, verifies it against Clerk's JWKS, and returns the authenticated
/// user's claims. Returns a 401 JSON error for any auth failure.
///
/// # Response
///
/// ```json
/// {
///   "user_id": "user_abc123",
///   "email": "user@example.com",
///   "token_issued_at": 1710849600,
///   "token_expires_at": 1710853200
/// }
/// ```
async fn handle_me(req: Request, ctx: worker::RouteContext<()>) -> worker::Result<Response> {
    let request_ctx = extract_request_context(&req);

    request_ctx.logger.info(
        "Authenticated endpoint requested",
        HashMap::from([(
            "path".to_string(),
            serde_json::Value::String("/me".to_string()),
        )]),
    );

    // Read the JWKS URL from environment
    let jwks_url = ctx
        .var("CLERK_JWKS_URL")
        .map(|v| v.to_string())
        .unwrap_or_else(|_| "https://api.clerk.com/v1/jwks".to_string());

    // Authenticate the request
    let claims = match authenticate_request(&req, &request_ctx, &jwks_url).await {
        Ok(claims) => claims,
        Err(auth_error) => {
            request_ctx.logger.warn(
                "Authentication failed for /me",
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

    let body = MeResponse {
        user_id: claims.sub,
        email: claims.email,
        token_issued_at: claims.iat,
        token_expires_at: claims.exp,
    };

    let json = serde_json::to_string(&body).map_err(|e| worker::Error::RustError(e.to_string()))?;

    flush_logs(&request_ctx, &ctx).await;

    let mut resp = Response::ok(json)?;
    let _ = resp.headers_mut().set("Content-Type", "application/json");
    attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;

    Ok(resp)
}

/// Best-effort flush of buffered logs to Axiom.
///
/// Reads the Axiom API token and dataset from the route context and
/// sends all buffered log entries. If the token is not configured or
/// the flush fails, the error is silently ignored so it never affects
/// the HTTP response.
async fn flush_logs(request_ctx: &middleware::RequestContext, ctx: &worker::RouteContext<()>) {
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
