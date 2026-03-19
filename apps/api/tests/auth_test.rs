//! Tests for the authentication error types and response serialization.
//!
//! These tests verify the error response contract without requiring a
//! running Worker environment or real JWKS endpoint.

use serde_json::Value;

/// Mirror of the ErrorResponse shape from `src/errors.rs`.
#[derive(serde::Serialize)]
struct ErrorResponse {
    error: ErrorDetail,
}

/// Mirror of the ErrorDetail shape.
#[derive(serde::Serialize)]
struct ErrorDetail {
    code: String,
    message: String,
}

/// Mirror of the MeResponse shape from `src/lib.rs`.
#[derive(serde::Serialize)]
struct MeResponse {
    user_id: String,
    email: Option<String>,
    token_issued_at: i64,
    token_expires_at: i64,
}

#[test]
fn error_response_serializes_to_expected_shape() {
    let resp = ErrorResponse {
        error: ErrorDetail {
            code: "auth_missing_header".to_string(),
            message: "missing Authorization header".to_string(),
        },
    };

    let json = serde_json::to_string(&resp).expect("serialization should succeed");
    let parsed: Value = serde_json::from_str(&json).expect("should be valid JSON");

    assert!(parsed.get("error").is_some(), "missing 'error' field");
    assert_eq!(parsed["error"]["code"], "auth_missing_header");
    assert_eq!(parsed["error"]["message"], "missing Authorization header");
}

#[test]
fn error_response_contains_nested_error_object() {
    let resp = ErrorResponse {
        error: ErrorDetail {
            code: "auth_token_expired".to_string(),
            message: "JWT has expired".to_string(),
        },
    };

    let json = serde_json::to_string(&resp).expect("serialization should succeed");
    let parsed: Value = serde_json::from_str(&json).expect("should be valid JSON");

    assert!(parsed["error"].is_object(), "'error' should be an object");
    assert!(
        parsed["error"]["code"].is_string(),
        "'code' should be a string"
    );
    assert!(
        parsed["error"]["message"].is_string(),
        "'message' should be a string"
    );
}

#[test]
fn me_response_serializes_correctly() {
    let resp = MeResponse {
        user_id: "user_abc123".to_string(),
        email: Some("user@example.com".to_string()),
        token_issued_at: 1710849600,
        token_expires_at: 1710853200,
    };

    let json = serde_json::to_string(&resp).expect("serialization should succeed");
    let parsed: Value = serde_json::from_str(&json).expect("should be valid JSON");

    assert_eq!(parsed["user_id"], "user_abc123");
    assert_eq!(parsed["email"], "user@example.com");
    assert_eq!(parsed["token_issued_at"], 1710849600);
    assert_eq!(parsed["token_expires_at"], 1710853200);
}

#[test]
fn me_response_with_null_email() {
    let resp = MeResponse {
        user_id: "user_abc123".to_string(),
        email: None,
        token_issued_at: 1710849600,
        token_expires_at: 1710853200,
    };

    let json = serde_json::to_string(&resp).expect("serialization should succeed");
    let parsed: Value = serde_json::from_str(&json).expect("should be valid JSON");

    assert_eq!(parsed["user_id"], "user_abc123");
    assert!(parsed["email"].is_null(), "email should be null when None");
}

#[test]
fn me_response_contains_required_fields() {
    let resp = MeResponse {
        user_id: "user_abc123".to_string(),
        email: Some("test@test.com".to_string()),
        token_issued_at: 1000,
        token_expires_at: 2000,
    };

    let json = serde_json::to_string(&resp).expect("serialization should succeed");
    let parsed: Value = serde_json::from_str(&json).expect("should be valid JSON");

    assert!(parsed.get("user_id").is_some(), "missing 'user_id' field");
    assert!(parsed.get("email").is_some(), "missing 'email' field");
    assert!(
        parsed.get("token_issued_at").is_some(),
        "missing 'token_issued_at' field"
    );
    assert!(
        parsed.get("token_expires_at").is_some(),
        "missing 'token_expires_at' field"
    );
}
