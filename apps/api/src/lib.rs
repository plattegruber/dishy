//! Dishy API — Cloudflare Worker entry point.
//!
//! This module sets up the Worker router and defines the available HTTP routes.
//! Public endpoints (health) are unauthenticated; protected endpoints (e.g. `/me`)
//! require a valid Clerk JWT in the `Authorization: Bearer <token>` header.

pub mod auth;
pub mod errors;
pub mod middleware;

use serde::Serialize;
use worker::{event, Context, Env, Request, Response, Router};

use crate::middleware::auth::{auth_error_response, authenticate_request, fetch_jwks};

/// Response payload for the health check endpoint.
#[derive(Serialize)]
struct HealthResponse {
    /// Operational status of the API.
    status: &'static str,
    /// Current version of the API, matching Cargo.toml.
    version: &'static str,
}

/// Response payload for the `GET /me` endpoint.
///
/// Returns the authenticated user's identity as extracted from the
/// verified Clerk JWT claims.
#[derive(Serialize)]
struct MeResponse {
    /// Clerk user ID (from the JWT `sub` claim).
    user_id: String,
    /// Token issuer (Clerk Frontend API URL), if present.
    #[serde(skip_serializing_if = "Option::is_none")]
    issuer: Option<String>,
    /// Clerk session ID, if present.
    #[serde(skip_serializing_if = "Option::is_none")]
    session_id: Option<String>,
    /// Authorized party origin, if present.
    #[serde(skip_serializing_if = "Option::is_none")]
    authorized_party: Option<String>,
}

/// Main fetch handler for all incoming HTTP requests.
///
/// Routes requests through the Worker router to the appropriate handler.
/// The health endpoint is unauthenticated; all other endpoints require
/// a valid Clerk JWT. Returns a 404 for any unmatched routes.
#[event(fetch)]
async fn fetch(req: Request, env: Env, _ctx: Context) -> worker::Result<Response> {
    console_error_panic_hook::set_once();

    let router = Router::new();

    router
        .get_async("/health", handle_health)
        .get_async("/me", handle_me)
        .run(req, env)
        .await
}

/// Handles GET /health requests.
///
/// Returns a JSON payload with the API status and version number.
/// Used by monitoring systems and CI/CD to verify the Worker is operational.
/// This endpoint is intentionally unauthenticated.
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

/// Handles GET /me requests.
///
/// Requires a valid Clerk JWT in the `Authorization: Bearer <token>` header.
/// Returns the authenticated user's identity extracted from the token claims.
///
/// On authentication failure, returns a 401 JSON error with a machine-readable
/// error code and human-readable message.
async fn handle_me(req: Request, ctx: worker::RouteContext<()>) -> worker::Result<Response> {
    // Resolve the JWKS URL from environment, falling back to Clerk's API endpoint.
    let jwks_url = ctx
        .var("CLERK_JWKS_URL")
        .map(|v| v.to_string())
        .unwrap_or_else(|_| "https://api.clerk.com/v1/jwks".to_string());

    // Fetch JWKS (in production this should be cached; Clerk rotates keys
    // infrequently so a short TTL cache is sufficient).
    let jwks = match fetch_jwks(&jwks_url).await {
        Ok(jwks) => jwks,
        Err(err) => return auth_error_response(&err),
    };

    // Authenticate the request.
    let claims = match authenticate_request(&req, &jwks) {
        Ok(claims) => claims,
        Err(err) => return auth_error_response(&err),
    };

    let body = MeResponse {
        user_id: claims.sub,
        issuer: claims.iss,
        session_id: claims.sid,
        authorized_party: claims.azp,
    };

    let json = serde_json::to_string(&body).map_err(|e| worker::Error::RustError(e.to_string()))?;

    Response::ok(json).map(|mut resp| {
        let _ = resp.headers_mut().set("Content-Type", "application/json");
        resp
    })
}
