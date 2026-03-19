//! Request middleware for correlation ID propagation, logging context, and
//! authentication.
//!
//! Extracts `X-Correlation-ID` and `X-Session-ID` headers from incoming
//! requests (generating a UUIDv4 for the correlation ID if none is
//! provided). These IDs are attached to a [`RequestContext`] that handlers
//! use throughout the request lifecycle, and the correlation ID is echoed
//! back on every response.
//!
//! The [`authenticate_request`] function extends this pipeline by extracting
//! the Bearer token from the `Authorization` header and verifying it as a
//! Clerk JWT, producing [`AuthClaims`] on success.

use std::collections::HashMap;

use uuid::Uuid;
use worker::Request;

use crate::auth::{self, AuthClaims};
use crate::errors::AuthError;
use crate::logging::Logger;

/// Header name for the correlation ID.
pub const CORRELATION_ID_HEADER: &str = "X-Correlation-ID";

/// Header name for the session ID.
pub const SESSION_ID_HEADER: &str = "X-Session-ID";

/// Header name for the authorization token.
pub const AUTHORIZATION_HEADER: &str = "Authorization";

/// Bearer token prefix (case-insensitive matching is applied).
const BEARER_PREFIX: &str = "Bearer ";

/// Per-request context carrying correlation metadata and a logger.
///
/// Created by [`extract_request_context`] at the start of every request.
/// Handlers use the embedded [`Logger`] for structured logging and read
/// the IDs when they need to propagate context to downstream services.
pub struct RequestContext {
    /// UUIDv4 correlation ID for this request (from header or generated).
    pub correlation_id: String,
    /// UUIDv4 session ID from the client, empty string if not provided.
    pub session_id: String,
    /// Structured logger pre-configured with the request's IDs.
    pub logger: Logger,
}

/// Extracts correlation and session IDs from request headers and builds
/// a [`RequestContext`].
///
/// If the `X-Correlation-ID` header is missing or empty, a new UUIDv4 is
/// generated. The `X-Session-ID` header is optional; when absent the
/// session ID defaults to an empty string.
///
/// # Arguments
///
/// * `req` — The incoming Worker request.
///
/// # Returns
///
/// A [`RequestContext`] ready for use by route handlers.
pub fn extract_request_context(req: &Request) -> RequestContext {
    let headers = req.headers();

    let correlation_id = headers
        .get(CORRELATION_ID_HEADER)
        .ok()
        .flatten()
        .filter(|v| !v.is_empty())
        .unwrap_or_else(|| Uuid::new_v4().to_string());

    let session_id = headers
        .get(SESSION_ID_HEADER)
        .ok()
        .flatten()
        .unwrap_or_default();

    let logger = Logger::new(correlation_id.clone(), session_id.clone());

    RequestContext {
        correlation_id,
        session_id,
        logger,
    }
}

/// Attaches the correlation ID to an outgoing response.
///
/// Adds the `X-Correlation-ID` header so clients and downstream
/// consumers can correlate the response with request-side logs.
///
/// # Errors
///
/// Returns the original `worker::Error` if header mutation fails.
pub fn attach_correlation_header(
    response: &mut worker::Response,
    correlation_id: &str,
) -> Result<(), worker::Error> {
    response
        .headers_mut()
        .set(CORRELATION_ID_HEADER, correlation_id)?;
    Ok(())
}

/// Extracts the Bearer token from the `Authorization` header.
///
/// Expects the header value to be in `Bearer <token>` format (with a
/// case-insensitive prefix match). Returns only the token portion.
fn extract_bearer_token(req: &Request) -> Result<String, AuthError> {
    let auth_header = req
        .headers()
        .get(AUTHORIZATION_HEADER)
        .ok()
        .flatten()
        .ok_or(AuthError::MissingAuthHeader)?;

    if auth_header.len() <= BEARER_PREFIX.len() {
        return Err(AuthError::InvalidAuthHeaderFormat);
    }

    let prefix = &auth_header[..BEARER_PREFIX.len()];
    if !prefix.eq_ignore_ascii_case(BEARER_PREFIX) {
        return Err(AuthError::InvalidAuthHeaderFormat);
    }

    let token = auth_header[BEARER_PREFIX.len()..].trim().to_string();
    if token.is_empty() {
        return Err(AuthError::InvalidAuthHeaderFormat);
    }

    Ok(token)
}

/// Authenticates an incoming request by verifying the Bearer JWT.
///
/// Extracts the token from the `Authorization` header, verifies it
/// against Clerk's JWKS endpoint, and returns the decoded claims on
/// success. Logs authentication outcomes (success or failure) to the
/// request's [`Logger`] for observability.
///
/// # Arguments
///
/// * `req` — The incoming Worker request.
/// * `request_ctx` — The request context with logger for structured logging.
/// * `jwks_url` — The Clerk JWKS endpoint URL.
///
/// # Errors
///
/// Returns an [`AuthError`] if the token is missing, malformed, expired,
/// or fails signature verification.
pub async fn authenticate_request(
    req: &Request,
    request_ctx: &RequestContext,
    jwks_url: &str,
) -> Result<AuthClaims, AuthError> {
    request_ctx.logger.debug(
        "Attempting JWT authentication",
        HashMap::from([(
            "jwks_url".to_string(),
            serde_json::Value::String(jwks_url.to_string()),
        )]),
    );

    let token = match extract_bearer_token(req) {
        Ok(t) => t,
        Err(e) => {
            request_ctx.logger.warn(
                "Authentication failed: missing or invalid Authorization header",
                HashMap::from([(
                    "error_code".to_string(),
                    serde_json::Value::String(e.code().to_string()),
                )]),
            );
            return Err(e);
        }
    };

    match auth::verify_token(&token, jwks_url).await {
        Ok(claims) => {
            request_ctx.logger.info(
                "Authentication successful",
                HashMap::from([(
                    "user_id".to_string(),
                    serde_json::Value::String(claims.sub.clone()),
                )]),
            );
            Ok(claims)
        }
        Err(e) => {
            request_ctx.logger.warn(
                "Authentication failed: JWT verification error",
                HashMap::from([
                    (
                        "error_code".to_string(),
                        serde_json::Value::String(e.code().to_string()),
                    ),
                    (
                        "error_message".to_string(),
                        serde_json::Value::String(e.to_string()),
                    ),
                ]),
            );
            Err(e)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn correlation_id_header_constant_is_correct() {
        assert_eq!(CORRELATION_ID_HEADER, "X-Correlation-ID");
    }

    #[test]
    fn session_id_header_constant_is_correct() {
        assert_eq!(SESSION_ID_HEADER, "X-Session-ID");
    }

    #[test]
    fn authorization_header_constant_is_correct() {
        assert_eq!(AUTHORIZATION_HEADER, "Authorization");
    }

    #[test]
    fn generated_correlation_id_is_valid_uuid() {
        let id = Uuid::new_v4().to_string();
        assert!(Uuid::parse_str(&id).is_ok(), "should be a valid UUID");
        assert_eq!(id.len(), 36, "UUID string should be 36 chars");
    }
}
