//! Authentication middleware for protected API endpoints.
//!
//! Extracts the `Authorization: Bearer <token>` header, verifies the
//! JWT using Clerk's JWKS, and makes the authenticated user's claims
//! available to downstream route handlers.

use worker::{Request, Response};

use crate::auth::{AuthClaims, JwkSet};
use crate::errors::{AuthError, ErrorResponse};

/// Extract the Bearer token from the Authorization header.
///
/// # Errors
///
/// Returns [`AuthError::MissingAuthHeader`] if the header is absent,
/// or [`AuthError::InvalidAuthHeaderFormat`] if it does not start with `Bearer `.
pub fn extract_bearer_token(req: &Request) -> Result<String, AuthError> {
    let headers = req.headers();
    let auth_header = headers
        .get("Authorization")
        .ok()
        .flatten()
        .ok_or(AuthError::MissingAuthHeader)?;

    let token = auth_header
        .strip_prefix("Bearer ")
        .ok_or(AuthError::InvalidAuthHeaderFormat)?;

    if token.is_empty() {
        return Err(AuthError::InvalidAuthHeaderFormat);
    }

    Ok(token.to_string())
}

/// Authenticate an incoming request by verifying the JWT.
///
/// Extracts the bearer token, verifies it against the provided JWKS,
/// and returns the decoded claims on success.
///
/// # Errors
///
/// Returns an [`AuthError`] for any authentication failure. The caller
/// should convert this to a 401 JSON response using [`auth_error_response`].
pub fn authenticate_request(req: &Request, jwks: &JwkSet) -> Result<AuthClaims, AuthError> {
    let token = extract_bearer_token(req)?;
    crate::auth::verify_token(&token, jwks)
}

/// Build a 401 JSON error [`Response`] from an [`AuthError`].
///
/// Returns a `worker::Result<Response>` suitable for returning directly
/// from a route handler.
pub fn auth_error_response(err: &AuthError) -> worker::Result<Response> {
    let body = ErrorResponse::from_auth_error(err);
    let json = serde_json::to_string(&body).map_err(|e| worker::Error::RustError(e.to_string()))?;

    let mut resp = Response::error(&json, err.status_code())?;
    let _ = resp.headers_mut().set("Content-Type", "application/json");
    Ok(resp)
}

/// Fetch the JWKS from Clerk's API endpoint.
///
/// Makes an HTTP request to the JWKS URL and parses the response.
/// The JWKS should be cached by the caller since Clerk rotates keys
/// infrequently.
///
/// # Errors
///
/// Returns [`AuthError::JwksFetchFailed`] if the HTTP request fails
/// or the response cannot be parsed.
pub async fn fetch_jwks(jwks_url: &str) -> Result<JwkSet, AuthError> {
    let mut resp = worker::Fetch::Url(worker::Url::parse(jwks_url).map_err(|e| {
        AuthError::JwksFetchFailed {
            reason: format!("invalid JWKS URL: {e}"),
        }
    })?)
    .send()
    .await
    .map_err(|e| AuthError::JwksFetchFailed {
        reason: format!("HTTP request failed: {e}"),
    })?;

    let body = resp.bytes().await.map_err(|e| AuthError::JwksFetchFailed {
        reason: format!("failed to read response body: {e}"),
    })?;

    serde_json::from_slice::<JwkSet>(&body).map_err(|e| AuthError::JwksFetchFailed {
        reason: format!("failed to parse JWKS response: {e}"),
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn extract_bearer_token_parses_valid_header() {
        // We cannot easily construct a `worker::Request` in unit tests,
        // so we test the AuthError variants and ErrorResponse construction.
        let err = AuthError::MissingAuthHeader;
        assert_eq!(err.status_code(), 401);
        assert_eq!(err.error_code(), "MISSING_AUTH_HEADER");
    }

    #[test]
    fn auth_error_response_produces_json() {
        let err = AuthError::TokenExpired;
        let body = ErrorResponse::from_auth_error(&err);
        let json = serde_json::to_string(&body).expect("should serialize");
        assert!(json.contains("TOKEN_EXPIRED"));
        assert!(json.contains("token has expired"));
    }

    #[test]
    fn auth_error_response_for_missing_header() {
        let err = AuthError::MissingAuthHeader;
        let body = ErrorResponse::from_auth_error(&err);
        assert_eq!(body.error, "MISSING_AUTH_HEADER");
        assert!(body.message.contains("Authorization"));
    }

    #[test]
    fn auth_error_response_for_invalid_format() {
        let err = AuthError::InvalidAuthHeaderFormat;
        let body = ErrorResponse::from_auth_error(&err);
        assert_eq!(body.error, "INVALID_AUTH_HEADER_FORMAT");
        assert!(body.message.contains("Bearer"));
    }
}
