//! Dishy API -- Cloudflare Worker entry point.
//!
//! This module sets up the Worker router and defines the available HTTP routes.
//! Serves a health check endpoint (unauthenticated), an authenticated `/me`
//! endpoint, and recipe CRUD endpoints (authenticated via Clerk JWT). All
//! requests are wrapped with correlation ID middleware for cross-service
//! observability via Axiom.

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
#[cfg(target_arch = "wasm32")]
use worker::Queue;
use worker::{event, Context, Env, Request, Response, Router};

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
        .get_async("/captures/:id", |req, route_ctx| async move {
            crate::routes::recipes::handle_get_capture_status(req, route_ctx).await
        })
        .run(req, env)
        .await
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

/// Queue event handler for async capture processing.
///
/// Consumes messages from the `dishy-capture-queue` Cloudflare Queue.
/// Each message contains a `CaptureJob` describing a social link or
/// screenshot capture to process. The handler:
///
/// 1. Deserializes the capture job from the queue message.
/// 2. Delegates to [`pipeline::queue::process_capture_job`] for processing.
/// 3. Acknowledges the message on success, or lets it retry on transient failure.
///
/// Non-transient failures (invalid input, extraction failure) are acknowledged
/// to prevent infinite retries — the capture record is marked as `Failed` in D1.
#[cfg(target_arch = "wasm32")]
#[event(queue)]
async fn queue_handler(
    message_batch: worker::MessageBatch<serde_json::Value>,
    env: Env,
    _ctx: Context,
) -> worker::Result<()> {
    use crate::pipeline::queue::{process_capture_job, CaptureJob};

    let db = env
        .d1("DB")
        .map_err(|e| worker::Error::RustError(format!("failed to get D1 binding: {e}")))?;

    let api_key = env
        .secret("ANTHROPIC_API_KEY")
        .map(|s| s.to_string())
        .unwrap_or_default();

    let fdc_api_key = env
        .secret("FDC_API_KEY")
        .map(|s| s.to_string())
        .unwrap_or_default();

    for message in message_batch.messages() {
        let logger = logging::Logger::new(uuid::Uuid::new_v4().to_string(), String::new());

        let job: CaptureJob = match serde_json::from_value(message.body().clone()) {
            Ok(j) => j,
            Err(e) => {
                logger.error(
                    "Failed to deserialize capture job from queue message",
                    HashMap::from([(
                        "error".to_string(),
                        serde_json::Value::String(e.to_string()),
                    )]),
                );
                // Acknowledge bad messages to prevent infinite retries
                message.ack();
                continue;
            }
        };

        logger.info(
            "Processing queued capture job",
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

        match process_capture_job(&job, &db, &api_key, &fdc_api_key, &logger).await {
            Ok(()) => {
                logger.info(
                    "Capture job processed successfully",
                    HashMap::from([(
                        "capture_id".to_string(),
                        serde_json::Value::String(job.capture_id.clone()),
                    )]),
                );
                message.ack();
            }
            Err(e) => {
                logger.error(
                    "Capture job processing failed",
                    HashMap::from([
                        (
                            "capture_id".to_string(),
                            serde_json::Value::String(job.capture_id.clone()),
                        ),
                        ("error".to_string(), serde_json::Value::String(e.clone())),
                    ]),
                );
                // Acknowledge anyway -- failure state is recorded in D1
                // The queue DLQ will catch truly unprocessable messages
                message.ack();
            }
        }

        // Best-effort flush logs for this job
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
    }

    Ok(())
}
