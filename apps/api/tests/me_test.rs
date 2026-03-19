//! Tests for the /me endpoint response structure.
//!
//! These tests verify the serialization contract of the MeResponse
//! and related auth structures without requiring a running Worker.

use serde::Serialize;
use serde_json::Value;

/// Mirror of the MeResponse struct used in the API.
/// Kept in sync with `src/lib.rs` to validate serialization.
#[derive(Serialize)]
struct MeResponse {
    user_id: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    issuer: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    session_id: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    authorized_party: Option<String>,
}

#[test]
fn me_response_serializes_minimal() {
    let response = MeResponse {
        user_id: "user_abc123".to_string(),
        issuer: None,
        session_id: None,
        authorized_party: None,
    };

    let json = serde_json::to_string(&response).expect("serialization should succeed");
    let parsed: Value = serde_json::from_str(&json).expect("should be valid JSON");

    assert_eq!(parsed["user_id"], "user_abc123");
    // Optional fields should be omitted when None
    assert!(parsed.get("issuer").is_none());
    assert!(parsed.get("session_id").is_none());
    assert!(parsed.get("authorized_party").is_none());
}

#[test]
fn me_response_serializes_full() {
    let response = MeResponse {
        user_id: "user_abc123".to_string(),
        issuer: Some("https://clerk.example.com".to_string()),
        session_id: Some("sess_xyz".to_string()),
        authorized_party: Some("https://myapp.example.com".to_string()),
    };

    let json = serde_json::to_string(&response).expect("serialization should succeed");
    let parsed: Value = serde_json::from_str(&json).expect("should be valid JSON");

    assert_eq!(parsed["user_id"], "user_abc123");
    assert_eq!(parsed["issuer"], "https://clerk.example.com");
    assert_eq!(parsed["session_id"], "sess_xyz");
    assert_eq!(parsed["authorized_party"], "https://myapp.example.com");
}

#[test]
fn me_response_user_id_is_required() {
    let response = MeResponse {
        user_id: "user_test".to_string(),
        issuer: None,
        session_id: None,
        authorized_party: None,
    };

    let json = serde_json::to_string(&response).expect("serialization should succeed");
    let parsed: Value = serde_json::from_str(&json).expect("should be valid JSON");

    assert!(
        parsed.get("user_id").is_some(),
        "user_id should always be present"
    );
    assert!(parsed["user_id"].is_string(), "user_id should be a string");
}
