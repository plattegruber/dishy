//! Dishy API — Cloudflare Worker entry point.
//!
//! This module sets up the Worker router and defines the available HTTP routes.
//! Currently serves a health check endpoint used for uptime monitoring and
//! deployment verification.

use serde::Serialize;
use worker::{event, Context, Env, Request, Response, Router};

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
        .get_async("/health", handle_health)
        .run(req, env)
        .await
}

/// Handles GET /health requests.
///
/// Returns a JSON payload with the API status and version number.
/// Used by monitoring systems and CI/CD to verify the Worker is operational.
async fn handle_health(_req: Request, _ctx: worker::RouteContext<()>) -> worker::Result<Response> {
    let body = HealthResponse {
        status: "ok",
        version: env!("CARGO_PKG_VERSION"),
    };

    let json = serde_json::to_string(&body).map_err(|e| worker::Error::RustError(e.to_string()))?;

    Response::ok(json).map(|mut resp| {
        let _ = resp.headers_mut().set("Content-Type", "application/json");
        resp
    })
}
