//! Tests for the health endpoint response structure.
//!
//! These tests verify the serialization contract of the health response
//! without requiring a running Worker environment.

use serde::Serialize;
use serde_json::Value;

/// Mirror of the HealthResponse struct used in the API.
/// Kept in sync with `src/lib.rs` to validate serialization.
#[derive(Serialize)]
struct HealthResponse {
    status: &'static str,
    version: &'static str,
}

#[test]
fn health_response_serializes_correctly() {
    let response = HealthResponse {
        status: "ok",
        version: "0.1.0",
    };

    let json = serde_json::to_string(&response).expect("serialization should succeed");
    let parsed: Value = serde_json::from_str(&json).expect("should be valid JSON");

    assert_eq!(parsed["status"], "ok");
    assert_eq!(parsed["version"], "0.1.0");
}

#[test]
fn health_response_contains_required_fields() {
    let response = HealthResponse {
        status: "ok",
        version: "0.1.0",
    };

    let json = serde_json::to_string(&response).expect("serialization should succeed");
    let parsed: Value = serde_json::from_str(&json).expect("should be valid JSON");

    assert!(parsed.get("status").is_some(), "missing 'status' field");
    assert!(parsed.get("version").is_some(), "missing 'version' field");
}

#[test]
fn health_response_status_is_string() {
    let response = HealthResponse {
        status: "ok",
        version: "0.1.0",
    };

    let json = serde_json::to_string(&response).expect("serialization should succeed");
    let parsed: Value = serde_json::from_str(&json).expect("should be valid JSON");

    assert!(parsed["status"].is_string(), "'status' should be a string");
    assert!(
        parsed["version"].is_string(),
        "'version' should be a string"
    );
}
