//! Structured error types for the Dishy API.
//!
//! Uses `thiserror` to derive user-facing error messages. Each variant
//! maps to a specific HTTP status code and JSON error response.

use serde::Serialize;

/// Authentication and authorization errors.
///
/// Each variant corresponds to a distinct failure mode in the JWT
/// verification pipeline and maps to a specific HTTP status code.
#[derive(Debug, thiserror::Error)]
pub enum AuthError {
    /// The `Authorization` header is missing from the request.
    #[error("missing Authorization header")]
    MissingAuthHeader,

    /// The `Authorization` header value is not in `Bearer <token>` format.
    #[error("invalid Authorization header format — expected 'Bearer <token>'")]
    InvalidAuthHeaderFormat,

    /// The JWT is structurally invalid and cannot be parsed.
    #[error("malformed token: {reason}")]
    MalformedToken {
        /// Human-readable description of the parse failure.
        reason: String,
    },

    /// No key in the JWKS matches the token's `kid` header.
    #[error("signing key not found: kid={kid}")]
    KeyNotFound {
        /// The key ID from the token header that was not found.
        kid: String,
    },

    /// The JWK cannot be used to build a decoding key.
    #[error("invalid key: {reason}")]
    InvalidKey {
        /// Human-readable description of the key issue.
        reason: String,
    },

    /// The token's `exp` claim indicates it has expired.
    #[error("token has expired")]
    TokenExpired,

    /// The token's `nbf` claim indicates it is not yet valid.
    #[error("token is not yet valid")]
    TokenNotYetValid,

    /// The cryptographic signature does not match.
    #[error("invalid token signature")]
    InvalidSignature,

    /// A catch-all for other verification failures.
    #[error("token verification failed: {reason}")]
    VerificationFailed {
        /// Description of the verification failure.
        reason: String,
    },

    /// Failed to fetch or parse the JWKS from Clerk.
    #[error("JWKS fetch failed: {reason}")]
    JwksFetchFailed {
        /// Description of the fetch failure.
        reason: String,
    },
}

impl AuthError {
    /// Returns the HTTP status code for this error.
    ///
    /// All authentication errors map to 401 Unauthorized.
    pub fn status_code(&self) -> u16 {
        401
    }

    /// Returns a machine-readable error code string.
    ///
    /// Suitable for use in JSON error responses so clients can
    /// programmatically handle specific error types.
    pub fn error_code(&self) -> &'static str {
        match self {
            Self::MissingAuthHeader => "MISSING_AUTH_HEADER",
            Self::InvalidAuthHeaderFormat => "INVALID_AUTH_HEADER_FORMAT",
            Self::MalformedToken { .. } => "MALFORMED_TOKEN",
            Self::KeyNotFound { .. } => "KEY_NOT_FOUND",
            Self::InvalidKey { .. } => "INVALID_KEY",
            Self::TokenExpired => "TOKEN_EXPIRED",
            Self::TokenNotYetValid => "TOKEN_NOT_YET_VALID",
            Self::InvalidSignature => "INVALID_SIGNATURE",
            Self::VerificationFailed { .. } => "VERIFICATION_FAILED",
            Self::JwksFetchFailed { .. } => "JWKS_FETCH_FAILED",
        }
    }
}

/// Structured JSON error response returned to API clients.
///
/// All error responses share this shape so clients can parse them
/// consistently regardless of the error type.
#[derive(Debug, Serialize)]
pub struct ErrorResponse {
    /// Machine-readable error code (e.g. `TOKEN_EXPIRED`).
    pub error: &'static str,
    /// Human-readable error message.
    pub message: String,
}

impl ErrorResponse {
    /// Build an [`ErrorResponse`] from an [`AuthError`].
    pub fn from_auth_error(err: &AuthError) -> Self {
        Self {
            error: err.error_code(),
            message: err.to_string(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn auth_error_status_code_is_401() {
        let errors: Vec<AuthError> = vec![
            AuthError::MissingAuthHeader,
            AuthError::InvalidAuthHeaderFormat,
            AuthError::MalformedToken {
                reason: "test".to_string(),
            },
            AuthError::KeyNotFound {
                kid: "k".to_string(),
            },
            AuthError::InvalidKey {
                reason: "test".to_string(),
            },
            AuthError::TokenExpired,
            AuthError::TokenNotYetValid,
            AuthError::InvalidSignature,
            AuthError::VerificationFailed {
                reason: "test".to_string(),
            },
            AuthError::JwksFetchFailed {
                reason: "test".to_string(),
            },
        ];

        for err in &errors {
            assert_eq!(err.status_code(), 401, "error {err:?} should be 401");
        }
    }

    #[test]
    fn auth_error_codes_are_uppercase_snake_case() {
        let errors: Vec<AuthError> = vec![
            AuthError::MissingAuthHeader,
            AuthError::InvalidAuthHeaderFormat,
            AuthError::TokenExpired,
            AuthError::TokenNotYetValid,
            AuthError::InvalidSignature,
        ];

        for err in &errors {
            let code = err.error_code();
            assert!(
                code.chars().all(|c| c.is_ascii_uppercase() || c == '_'),
                "error code '{code}' should be UPPER_SNAKE_CASE"
            );
        }
    }

    #[test]
    fn error_response_from_auth_error_serializes_correctly() {
        let err = AuthError::TokenExpired;
        let response = ErrorResponse::from_auth_error(&err);

        let json = serde_json::to_string(&response).expect("should serialize");
        let parsed: serde_json::Value = serde_json::from_str(&json).expect("should parse");

        assert_eq!(parsed["error"], "TOKEN_EXPIRED");
        assert_eq!(parsed["message"], "token has expired");
    }

    #[test]
    fn error_response_includes_reason_in_message() {
        let err = AuthError::MalformedToken {
            reason: "missing dot separator".to_string(),
        };
        let response = ErrorResponse::from_auth_error(&err);

        assert!(response.message.contains("missing dot separator"));
        assert_eq!(response.error, "MALFORMED_TOKEN");
    }

    #[test]
    fn auth_error_display_messages_are_descriptive() {
        assert_eq!(
            AuthError::MissingAuthHeader.to_string(),
            "missing Authorization header"
        );
        assert_eq!(AuthError::TokenExpired.to_string(), "token has expired");
        assert_eq!(
            AuthError::InvalidSignature.to_string(),
            "invalid token signature"
        );
    }
}
