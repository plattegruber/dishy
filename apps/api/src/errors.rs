//! Structured error types for authentication and API responses.
//!
//! Provides typed error enums that convert cleanly to JSON error responses
//! suitable for HTTP clients. All auth failures produce 401 responses with
//! a machine-readable `code` and human-readable `message`.

use serde::Serialize;

/// Errors that can occur during authentication.
///
/// Each variant maps to a specific failure mode in the JWT verification
/// pipeline. All variants produce a 401 HTTP response when converted to
/// an [`ErrorResponse`].
#[derive(Debug, thiserror::Error)]
pub enum AuthError {
    /// The `Authorization` header is missing from the request.
    #[error("missing Authorization header")]
    MissingAuthHeader,

    /// The `Authorization` header value is not in `Bearer <token>` format.
    #[error("invalid Authorization header format — expected 'Bearer <token>'")]
    InvalidAuthHeaderFormat,

    /// The JWT header could not be decoded from base64 or parsed as JSON.
    #[error("malformed JWT header: {0}")]
    MalformedHeader(String),

    /// The JWT uses an unsupported algorithm (only RS256 is accepted).
    #[error("unsupported JWT algorithm: {0}")]
    UnsupportedAlgorithm(String),

    /// The JWT payload could not be decoded from base64 or parsed as JSON.
    #[error("malformed JWT payload: {0}")]
    MalformedPayload(String),

    /// The JWKS could not be fetched or parsed from Clerk's endpoint.
    #[error("failed to fetch or parse JWKS: {0}")]
    JwksFetchFailed(String),

    /// No matching key was found in the JWKS for the JWT's `kid`.
    #[error("no matching key found in JWKS for kid '{0}'")]
    KeyNotFound(String),

    /// The RSA public key components (`n` or `e`) are invalid.
    #[error("invalid RSA key components: {0}")]
    InvalidKeyComponents(String),

    /// The JWT signature verification failed.
    #[error("JWT signature verification failed")]
    SignatureInvalid,

    /// The JWT has expired (current time is past `exp`).
    #[error("JWT has expired")]
    TokenExpired,

    /// The JWT is not yet valid (current time is before `iat`).
    #[error("JWT is not yet valid")]
    TokenNotYetValid,

    /// A required claim is missing from the JWT payload.
    #[error("missing required claim: {0}")]
    MissingClaim(String),

    /// A WebCrypto API operation failed.
    #[error("crypto operation failed: {0}")]
    CryptoError(String),
}

/// JSON-serializable error response body.
///
/// Returned in all error HTTP responses so clients receive a consistent,
/// machine-readable error shape:
///
/// ```json
/// { "error": { "code": "auth_expired", "message": "JWT has expired" } }
/// ```
#[derive(Debug, Serialize)]
pub struct ErrorResponse {
    /// Nested error object containing the code and message.
    pub error: ErrorDetail,
}

/// Inner error detail with a machine-readable code and human-readable message.
#[derive(Debug, Serialize)]
pub struct ErrorDetail {
    /// Machine-readable error code (e.g. `"auth_missing_header"`).
    pub code: String,
    /// Human-readable description of the error.
    pub message: String,
}

impl AuthError {
    /// Returns a machine-readable error code for this variant.
    pub fn code(&self) -> &'static str {
        match self {
            AuthError::MissingAuthHeader => "auth_missing_header",
            AuthError::InvalidAuthHeaderFormat => "auth_invalid_header_format",
            AuthError::MalformedHeader(_) => "auth_malformed_header",
            AuthError::UnsupportedAlgorithm(_) => "auth_unsupported_algorithm",
            AuthError::MalformedPayload(_) => "auth_malformed_payload",
            AuthError::JwksFetchFailed(_) => "auth_jwks_fetch_failed",
            AuthError::KeyNotFound(_) => "auth_key_not_found",
            AuthError::InvalidKeyComponents(_) => "auth_invalid_key",
            AuthError::SignatureInvalid => "auth_signature_invalid",
            AuthError::TokenExpired => "auth_token_expired",
            AuthError::TokenNotYetValid => "auth_token_not_yet_valid",
            AuthError::MissingClaim(_) => "auth_missing_claim",
            AuthError::CryptoError(_) => "auth_crypto_error",
        }
    }

    /// Converts this error into a JSON [`ErrorResponse`].
    pub fn to_error_response(&self) -> ErrorResponse {
        ErrorResponse {
            error: ErrorDetail {
                code: self.code().to_string(),
                message: self.to_string(),
            },
        }
    }

    /// Converts this error into a `worker::Response` with status 401.
    ///
    /// The response body is a JSON-serialized [`ErrorResponse`] with
    /// `Content-Type: application/json`.
    pub fn to_response(&self) -> worker::Result<worker::Response> {
        let body = self.to_error_response();
        let json =
            serde_json::to_string(&body).map_err(|e| worker::Error::RustError(e.to_string()))?;
        let mut resp = worker::Response::error(&json, 401)?;
        let _ = resp.headers_mut().set("Content-Type", "application/json");
        Ok(resp)
    }
}
