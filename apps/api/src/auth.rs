//! JWT verification module for Clerk authentication.
//!
//! Validates Clerk-issued JWTs using RS256 signatures. Public keys are
//! fetched from Clerk's JWKS endpoint and used with the Web Crypto API
//! (available in the Cloudflare Workers runtime) to verify token
//! signatures without pulling in native crypto dependencies that don't
//! compile to `wasm32-unknown-unknown`.
//!
//! # Flow
//!
//! 1. Decode the JWT header to extract the `kid` (Key ID).
//! 2. Fetch the JWKS from Clerk and find the matching key.
//! 3. Import the RSA public key via Web Crypto.
//! 4. Verify the RS256 signature.
//! 5. Decode and validate the payload claims (exp, iat, sub).

use base64::{engine::general_purpose::URL_SAFE_NO_PAD, Engine as _};
use serde::{Deserialize, Serialize};

use crate::errors::AuthError;

/// Decoded JWT header.
#[derive(Debug, Deserialize)]
struct JwtHeader {
    /// Signing algorithm (must be `"RS256"`).
    alg: String,
    /// Key ID used to select the correct JWKS key.
    kid: Option<String>,
}

/// Authenticated user claims extracted from a verified Clerk JWT.
///
/// Contains the essential identity fields from the token payload.
/// Only populated after successful signature verification and claim
/// validation.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthClaims {
    /// Clerk user ID (the JWT `sub` claim).
    pub sub: String,
    /// User's primary email address, if present in the token.
    pub email: Option<String>,
    /// Unix timestamp when the token was issued.
    pub iat: i64,
    /// Unix timestamp when the token expires.
    pub exp: i64,
}

/// A single JSON Web Key from the JWKS response.
#[derive(Debug, Deserialize)]
#[allow(dead_code)]
struct Jwk {
    /// Key type (expected `"RSA"`).
    kty: String,
    /// Key ID.
    kid: Option<String>,
    /// Algorithm (expected `"RS256"`).
    #[serde(default)]
    alg: Option<String>,
    /// RSA modulus, base64url-encoded.
    n: String,
    /// RSA public exponent, base64url-encoded.
    e: String,
}

/// JWKS response from Clerk's well-known endpoint.
#[derive(Debug, Deserialize)]
struct JwksResponse {
    /// List of JSON Web Keys.
    keys: Vec<Jwk>,
}

/// Splits a JWT into its three base64url-encoded parts.
///
/// Returns `(header, payload, signature)` or an error if the token
/// does not have exactly three dot-separated segments.
fn split_jwt(token: &str) -> Result<(&str, &str, &str), AuthError> {
    let parts: Vec<&str> = token.split('.').collect();
    if parts.len() != 3 {
        return Err(AuthError::MalformedHeader(
            "JWT must have exactly 3 segments".to_string(),
        ));
    }
    Ok((parts[0], parts[1], parts[2]))
}

/// Decodes the JWT header from base64url and parses it as JSON.
fn decode_header(header_b64: &str) -> Result<JwtHeader, AuthError> {
    let bytes = URL_SAFE_NO_PAD
        .decode(header_b64)
        .map_err(|e| AuthError::MalformedHeader(format!("base64 decode failed: {e}")))?;
    serde_json::from_slice(&bytes)
        .map_err(|e| AuthError::MalformedHeader(format!("JSON parse failed: {e}")))
}

/// Decodes the JWT payload from base64url and extracts [`AuthClaims`].
///
/// Validates that the token has not expired and that `iat` is not in
/// the future. A 60-second leeway is applied to account for clock skew.
fn decode_and_validate_payload(payload_b64: &str) -> Result<AuthClaims, AuthError> {
    let bytes = URL_SAFE_NO_PAD
        .decode(payload_b64)
        .map_err(|e| AuthError::MalformedPayload(format!("base64 decode failed: {e}")))?;

    let value: serde_json::Value = serde_json::from_slice(&bytes)
        .map_err(|e| AuthError::MalformedPayload(format!("JSON parse failed: {e}")))?;

    let sub = value
        .get("sub")
        .and_then(|v| v.as_str())
        .ok_or_else(|| AuthError::MissingClaim("sub".to_string()))?
        .to_string();

    let email = value
        .get("email")
        .and_then(|v| v.as_str())
        .map(String::from);

    let iat = value
        .get("iat")
        .and_then(|v| v.as_i64())
        .ok_or_else(|| AuthError::MissingClaim("iat".to_string()))?;

    let exp = value
        .get("exp")
        .and_then(|v| v.as_i64())
        .ok_or_else(|| AuthError::MissingClaim("exp".to_string()))?;

    // Validate expiration with 60-second leeway
    let now = chrono::Utc::now().timestamp();
    let leeway = 60;

    if now > exp + leeway {
        return Err(AuthError::TokenExpired);
    }

    if iat > now + leeway {
        return Err(AuthError::TokenNotYetValid);
    }

    Ok(AuthClaims {
        sub,
        email,
        iat,
        exp,
    })
}

/// Fetches the JWKS from Clerk's endpoint and finds the key matching `kid`.
///
/// If `kid` is `None`, returns the first RSA key in the set.
async fn fetch_jwk(jwks_url: &str, kid: Option<&str>) -> Result<Jwk, AuthError> {
    let request = worker::Request::new(jwks_url, worker::Method::Get)
        .map_err(|e| AuthError::JwksFetchFailed(format!("failed to build request: {e}")))?;

    let mut response = worker::Fetch::Request(request)
        .send()
        .await
        .map_err(|e| AuthError::JwksFetchFailed(format!("fetch failed: {e}")))?;

    if response.status_code() >= 400 {
        return Err(AuthError::JwksFetchFailed(format!(
            "JWKS endpoint returned HTTP {}",
            response.status_code()
        )));
    }

    let body = response
        .text()
        .await
        .map_err(|e| AuthError::JwksFetchFailed(format!("failed to read body: {e}")))?;

    let jwks: JwksResponse = serde_json::from_str(&body)
        .map_err(|e| AuthError::JwksFetchFailed(format!("failed to parse JWKS: {e}")))?;

    // Find matching key
    let key = match kid {
        Some(kid_value) => jwks
            .keys
            .into_iter()
            .find(|k| k.kid.as_deref() == Some(kid_value)),
        None => jwks.keys.into_iter().find(|k| k.kty == "RSA"),
    };

    key.ok_or_else(|| AuthError::KeyNotFound(kid.unwrap_or("<none>").to_string()))
}

/// Verifies the RS256 signature of a JWT using the Web Crypto API.
///
/// This function runs in the Cloudflare Workers runtime where the
/// Web Crypto API is available globally. It:
///
/// 1. Constructs a JWK object from the RSA `n` and `e` components.
/// 2. Imports the key via `crypto.subtle.importKey`.
/// 3. Verifies the signature via `crypto.subtle.verify`.
///
/// # Arguments
///
/// * `header_b64` — Base64url-encoded JWT header.
/// * `payload_b64` — Base64url-encoded JWT payload.
/// * `signature_b64` — Base64url-encoded JWT signature.
/// * `jwk` — The JWK containing the RSA public key.
#[cfg(target_arch = "wasm32")]
async fn verify_signature(
    header_b64: &str,
    payload_b64: &str,
    signature_b64: &str,
    jwk: &Jwk,
) -> Result<(), AuthError> {
    use js_sys::{ArrayBuffer, Object, Reflect, Uint8Array};
    use wasm_bindgen::JsValue;
    use wasm_bindgen_futures::JsFuture;

    // Get the global crypto.subtle object
    let global = js_sys::global();
    let crypto = Reflect::get(&global, &JsValue::from_str("crypto"))
        .map_err(|_| AuthError::CryptoError("crypto not available".to_string()))?;
    let subtle = Reflect::get(&crypto, &JsValue::from_str("subtle"))
        .map_err(|_| AuthError::CryptoError("subtle not available".to_string()))?;

    // Build the JWK object for importKey
    let jwk_obj = Object::new();
    Reflect::set(
        &jwk_obj,
        &JsValue::from_str("kty"),
        &JsValue::from_str("RSA"),
    )
    .map_err(|_| AuthError::CryptoError("failed to set kty".to_string()))?;
    Reflect::set(
        &jwk_obj,
        &JsValue::from_str("n"),
        &JsValue::from_str(&jwk.n),
    )
    .map_err(|_| AuthError::CryptoError("failed to set n".to_string()))?;
    Reflect::set(
        &jwk_obj,
        &JsValue::from_str("e"),
        &JsValue::from_str(&jwk.e),
    )
    .map_err(|_| AuthError::CryptoError("failed to set e".to_string()))?;
    Reflect::set(
        &jwk_obj,
        &JsValue::from_str("alg"),
        &JsValue::from_str("RS256"),
    )
    .map_err(|_| AuthError::CryptoError("failed to set alg".to_string()))?;
    Reflect::set(
        &jwk_obj,
        &JsValue::from_str("ext"),
        &JsValue::from_bool(true),
    )
    .map_err(|_| AuthError::CryptoError("failed to set ext".to_string()))?;

    // Build the algorithm object for RSASSA-PKCS1-v1_5
    let algo = Object::new();
    Reflect::set(
        &algo,
        &JsValue::from_str("name"),
        &JsValue::from_str("RSASSA-PKCS1-v1_5"),
    )
    .map_err(|_| AuthError::CryptoError("failed to set algorithm name".to_string()))?;
    let hash = Object::new();
    Reflect::set(
        &hash,
        &JsValue::from_str("name"),
        &JsValue::from_str("SHA-256"),
    )
    .map_err(|_| AuthError::CryptoError("failed to set hash name".to_string()))?;
    Reflect::set(&algo, &JsValue::from_str("hash"), &hash)
        .map_err(|_| AuthError::CryptoError("failed to set hash".to_string()))?;

    // Key usages
    let usages = js_sys::Array::new();
    usages.push(&JsValue::from_str("verify"));

    // Import the key
    let import_key_fn = Reflect::get(&subtle, &JsValue::from_str("importKey"))
        .map_err(|_| AuthError::CryptoError("importKey not available".to_string()))?;
    let import_key_fn: js_sys::Function = import_key_fn
        .dyn_into()
        .map_err(|_| AuthError::CryptoError("importKey is not a function".to_string()))?;

    let import_promise = import_key_fn
        .call5(
            &subtle,
            &JsValue::from_str("jwk"),
            &jwk_obj,
            &algo,
            &JsValue::from_bool(false),
            &usages,
        )
        .map_err(|e| AuthError::CryptoError(format!("importKey call failed: {e:?}")))?;

    let crypto_key = JsFuture::from(js_sys::Promise::from(import_promise))
        .await
        .map_err(|e| AuthError::CryptoError(format!("importKey rejected: {e:?}")))?;

    // Decode the signature
    let sig_bytes = URL_SAFE_NO_PAD
        .decode(signature_b64)
        .map_err(|e| AuthError::MalformedHeader(format!("signature base64 decode failed: {e}")))?;
    let sig_array = Uint8Array::from(sig_bytes.as_slice());

    // Build the data to verify (header.payload)
    let signing_input = format!("{header_b64}.{payload_b64}");
    let data_array = Uint8Array::from(signing_input.as_bytes());

    // Verify the signature
    let verify_fn = Reflect::get(&subtle, &JsValue::from_str("verify"))
        .map_err(|_| AuthError::CryptoError("verify not available".to_string()))?;
    let verify_fn: js_sys::Function = verify_fn
        .dyn_into()
        .map_err(|_| AuthError::CryptoError("verify is not a function".to_string()))?;

    let verify_promise = verify_fn
        .call4(
            &subtle,
            &algo,
            &crypto_key,
            &sig_array.buffer().into(),
            &data_array.buffer().into(),
        )
        .map_err(|e| AuthError::CryptoError(format!("verify call failed: {e:?}")))?;

    let result = JsFuture::from(js_sys::Promise::from(verify_promise))
        .await
        .map_err(|e| AuthError::CryptoError(format!("verify rejected: {e:?}")))?;

    let valid = result.as_bool().unwrap_or(false);
    if !valid {
        return Err(AuthError::SignatureInvalid);
    }

    Ok(())
}

/// Stub signature verification for non-WASM targets (used in unit tests).
///
/// Always returns `Ok(())` since the Web Crypto API is not available
/// outside of the Cloudflare Workers runtime.
#[cfg(not(target_arch = "wasm32"))]
async fn verify_signature(
    _header_b64: &str,
    _payload_b64: &str,
    _signature_b64: &str,
    _jwk: &Jwk,
) -> Result<(), AuthError> {
    Ok(())
}

/// Verifies a Clerk JWT and returns the authenticated user's claims.
///
/// Performs the full verification pipeline:
///
/// 1. Splits the token into header, payload, and signature.
/// 2. Decodes the header and validates the algorithm is RS256.
/// 3. Fetches the JWKS from Clerk and selects the matching key.
/// 4. Verifies the RS256 signature using the Web Crypto API.
/// 5. Decodes and validates the payload claims.
///
/// # Arguments
///
/// * `token` — The raw JWT string (without the `Bearer ` prefix).
/// * `jwks_url` — The Clerk JWKS endpoint URL.
///
/// # Errors
///
/// Returns an [`AuthError`] for any verification failure. See the enum
/// variants for all possible failure modes.
pub async fn verify_token(token: &str, jwks_url: &str) -> Result<AuthClaims, AuthError> {
    let (header_b64, payload_b64, signature_b64) = split_jwt(token)?;

    // Decode and validate the header
    let header = decode_header(header_b64)?;
    if header.alg != "RS256" {
        return Err(AuthError::UnsupportedAlgorithm(header.alg));
    }

    // Fetch the matching JWK
    let jwk = fetch_jwk(jwks_url, header.kid.as_deref()).await?;

    // Verify that the JWK is an RSA key
    if jwk.kty != "RSA" {
        return Err(AuthError::InvalidKeyComponents(format!(
            "expected RSA key, got {}",
            jwk.kty
        )));
    }

    // Verify the algorithm matches if specified in the JWK
    if let Some(ref jwk_alg) = jwk.alg {
        if jwk_alg != "RS256" {
            return Err(AuthError::UnsupportedAlgorithm(jwk_alg.clone()));
        }
    }

    // Verify the signature
    verify_signature(header_b64, payload_b64, signature_b64, &jwk).await?;

    // Decode and validate the payload claims
    decode_and_validate_payload(payload_b64)
}

#[cfg(test)]
mod tests {
    use super::*;
    use base64::engine::general_purpose::URL_SAFE_NO_PAD;

    /// Helper to build a base64url-encoded JSON string.
    fn b64_json(value: &serde_json::Value) -> String {
        URL_SAFE_NO_PAD.encode(serde_json::to_vec(value).expect("serialization should succeed"))
    }

    #[test]
    fn split_jwt_returns_three_parts() {
        let (h, p, s) = split_jwt("aaa.bbb.ccc").expect("should split");
        assert_eq!(h, "aaa");
        assert_eq!(p, "bbb");
        assert_eq!(s, "ccc");
    }

    #[test]
    fn split_jwt_rejects_two_parts() {
        let result = split_jwt("aaa.bbb");
        assert!(result.is_err());
    }

    #[test]
    fn split_jwt_rejects_four_parts() {
        let result = split_jwt("a.b.c.d");
        assert!(result.is_err());
    }

    #[test]
    fn decode_header_parses_valid_rs256() {
        let header_json = serde_json::json!({"alg": "RS256", "typ": "JWT", "kid": "key-123"});
        let encoded = b64_json(&header_json);
        let header = decode_header(&encoded).expect("should decode");
        assert_eq!(header.alg, "RS256");
        assert_eq!(header.kid.as_deref(), Some("key-123"));
    }

    #[test]
    fn decode_header_fails_on_invalid_base64() {
        let result = decode_header("!!!invalid!!!");
        assert!(result.is_err());
    }

    #[test]
    fn decode_header_fails_on_invalid_json() {
        let encoded = URL_SAFE_NO_PAD.encode("not json");
        let result = decode_header(&encoded);
        assert!(result.is_err());
    }

    #[test]
    fn decode_and_validate_payload_succeeds_with_valid_claims() {
        let now = chrono::Utc::now().timestamp();
        let payload = serde_json::json!({
            "sub": "user_abc123",
            "email": "test@example.com",
            "iat": now - 10,
            "exp": now + 300,
        });
        let encoded = b64_json(&payload);
        let claims = decode_and_validate_payload(&encoded).expect("should succeed");
        assert_eq!(claims.sub, "user_abc123");
        assert_eq!(claims.email.as_deref(), Some("test@example.com"));
    }

    #[test]
    fn decode_and_validate_payload_allows_missing_email() {
        let now = chrono::Utc::now().timestamp();
        let payload = serde_json::json!({
            "sub": "user_abc123",
            "iat": now - 10,
            "exp": now + 300,
        });
        let encoded = b64_json(&payload);
        let claims = decode_and_validate_payload(&encoded).expect("should succeed");
        assert_eq!(claims.sub, "user_abc123");
        assert!(claims.email.is_none());
    }

    #[test]
    fn decode_and_validate_payload_rejects_expired_token() {
        let now = chrono::Utc::now().timestamp();
        let payload = serde_json::json!({
            "sub": "user_abc123",
            "iat": now - 600,
            "exp": now - 120, // expired 2 minutes ago (beyond 60s leeway)
        });
        let encoded = b64_json(&payload);
        let result = decode_and_validate_payload(&encoded);
        assert!(matches!(result, Err(AuthError::TokenExpired)));
    }

    #[test]
    fn decode_and_validate_payload_rejects_future_iat() {
        let now = chrono::Utc::now().timestamp();
        let payload = serde_json::json!({
            "sub": "user_abc123",
            "iat": now + 300, // 5 minutes in the future (beyond 60s leeway)
            "exp": now + 600,
        });
        let encoded = b64_json(&payload);
        let result = decode_and_validate_payload(&encoded);
        assert!(matches!(result, Err(AuthError::TokenNotYetValid)));
    }

    #[test]
    fn decode_and_validate_payload_rejects_missing_sub() {
        let now = chrono::Utc::now().timestamp();
        let payload = serde_json::json!({
            "iat": now - 10,
            "exp": now + 300,
        });
        let encoded = b64_json(&payload);
        let result = decode_and_validate_payload(&encoded);
        assert!(matches!(result, Err(AuthError::MissingClaim(_))));
    }

    #[test]
    fn decode_and_validate_payload_rejects_missing_exp() {
        let now = chrono::Utc::now().timestamp();
        let payload = serde_json::json!({
            "sub": "user_abc123",
            "iat": now - 10,
        });
        let encoded = b64_json(&payload);
        let result = decode_and_validate_payload(&encoded);
        assert!(matches!(result, Err(AuthError::MissingClaim(_))));
    }

    #[test]
    fn decode_and_validate_payload_rejects_missing_iat() {
        let now = chrono::Utc::now().timestamp();
        let payload = serde_json::json!({
            "sub": "user_abc123",
            "exp": now + 300,
        });
        let encoded = b64_json(&payload);
        let result = decode_and_validate_payload(&encoded);
        assert!(matches!(result, Err(AuthError::MissingClaim(_))));
    }

    #[test]
    fn auth_claims_serializes_correctly() {
        let claims = AuthClaims {
            sub: "user_123".to_string(),
            email: Some("user@example.com".to_string()),
            iat: 1000,
            exp: 2000,
        };
        let json = serde_json::to_value(&claims).expect("should serialize");
        assert_eq!(json["sub"], "user_123");
        assert_eq!(json["email"], "user@example.com");
        assert_eq!(json["iat"], 1000);
        assert_eq!(json["exp"], 2000);
    }

    #[test]
    fn auth_claims_deserializes_correctly() {
        let json = serde_json::json!({
            "sub": "user_456",
            "email": "test@test.com",
            "iat": 3000,
            "exp": 4000,
        });
        let claims: AuthClaims = serde_json::from_value(json).expect("should deserialize");
        assert_eq!(claims.sub, "user_456");
        assert_eq!(claims.email.as_deref(), Some("test@test.com"));
        assert_eq!(claims.iat, 3000);
        assert_eq!(claims.exp, 4000);
    }
}
