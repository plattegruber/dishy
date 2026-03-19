//! Dishy API — Cloudflare Worker entry point.
//!
//! This module sets up the Worker router and defines the available HTTP routes.
//! Currently serves a health check endpoint used for uptime monitoring and
//! deployment verification. All requests are wrapped with correlation ID
//! middleware for cross-service observability via Axiom.

pub mod logging;
pub mod middleware;

use std::collections::HashMap;

use serde::Serialize;
use worker::{event, Context, Env, Request, Response, Router};

use crate::middleware::{attach_correlation_header, extract_request_context};

/// Response payload for the health check endpoint.
#[derive(Serialize)]
struct HealthResponse {
    /// Operational status of the API.
    status: &'static str,
    /// Current version of the API, matching Cargo.toml.
    version: &'static str,
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
        .run(req, env)
        .await
}

/// Handles GET /health requests.
///
/// Returns a JSON payload with the API status and version number.
/// Uses structured logging with correlation ID context and flushes
/// logs to Axiom at the end of the request. Used by monitoring systems
/// and CI/CD to verify the Worker is operational.
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
    let axiom_token = ctx
        .secret("AXIOM_API_TOKEN")
        .map(|s| s.to_string())
        .unwrap_or_default();
    let axiom_dataset = ctx
        .var("AXIOM_DATASET")
        .map(|v| v.to_string())
        .unwrap_or_else(|_| "dishy-api".to_string());

    if !axiom_token.is_empty() {
        // Best-effort flush — do not fail the request on logging errors
        let _ = request_ctx.logger.flush(&axiom_token, &axiom_dataset).await;
    }

    let mut resp = Response::ok(json)?;
    let _ = resp.headers_mut().set("Content-Type", "application/json");
    attach_correlation_header(&mut resp, request_ctx.logger.correlation_id())?;

    Ok(resp)
}
