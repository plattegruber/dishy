//! JWT verification for Clerk-issued tokens.
//!
//! This module handles decoding and validating JWTs issued by Clerk,
//! extracting typed claims for use in authenticated route handlers.
//! It fetches Clerk's JWKS endpoint to obtain public keys and caches
//! them for efficient repeated verification.

use base64::{engine::general_purpose::URL_SAFE_NO_PAD, Engine as _};
use jsonwebtoken::{decode, Algorithm, DecodingKey, Validation};
use serde::{Deserialize, Serialize};

use crate::errors::AuthError;

/// Claims extracted from a verified Clerk JWT.
///
/// Contains the user identity and session metadata encoded in the
/// token. The `sub` field is the Clerk user ID (e.g. `user_xxx`).
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct AuthClaims {
    /// Clerk user ID (the JWT `sub` claim).
    pub sub: String,
    /// Token issuer URL (Clerk Frontend API).
    #[serde(default)]
    pub iss: Option<String>,
    /// Token expiration time (Unix timestamp).
    #[serde(default)]
    pub exp: Option<u64>,
    /// Token "not before" time (Unix timestamp).
    #[serde(default)]
    pub nbf: Option<u64>,
    /// Issued-at time (Unix timestamp).
    #[serde(default)]
    pub iat: Option<u64>,
    /// JWT ID.
    #[serde(default)]
    pub jti: Option<String>,
    /// Authorized party — the origin that requested the token.
    #[serde(default)]
    pub azp: Option<String>,
    /// Clerk session ID.
    #[serde(default)]
    pub sid: Option<String>,
}

/// A single JWK (JSON Web Key) as returned by Clerk's JWKS endpoint.
///
/// Only RSA keys are supported since Clerk uses RS256.
#[derive(Debug, Clone, Deserialize)]
pub struct Jwk {
    /// Key type (e.g. "RSA").
    pub kty: String,
    /// Key ID used to match against the JWT header `kid`.
    pub kid: Option<String>,
    /// RSA modulus (base64url-encoded).
    pub n: Option<String>,
    /// RSA public exponent (base64url-encoded).
    pub e: Option<String>,
    /// Algorithm (e.g. "RS256").
    pub alg: Option<String>,
    /// Intended use of the key (e.g. "sig").
    #[serde(rename = "use")]
    pub use_: Option<String>,
}

/// A JWKS (JSON Web Key Set) response from Clerk.
///
/// Contains one or more public keys used to verify JWT signatures.
#[derive(Debug, Clone, Deserialize)]
pub struct JwkSet {
    /// The set of JSON Web Keys.
    pub keys: Vec<Jwk>,
}

impl JwkSet {
    /// Find a key by its key ID (`kid`).
    ///
    /// Returns `None` if no key with the given `kid` exists in the set.
    pub fn find(&self, kid: &str) -> Option<&Jwk> {
        self.keys.iter().find(|k| k.kid.as_deref() == Some(kid))
    }
}

/// Extracts the `kid` (key ID) from a JWT header without verifying the signature.
///
/// This is used to look up the correct public key from the JWKS before
/// performing full verification.
///
/// # Errors
///
/// Returns [`AuthError::MalformedToken`] if the token cannot be decoded
/// or the header is missing the `kid` field.
pub fn extract_kid_from_token(token: &str) -> Result<String, AuthError> {
    let header = jsonwebtoken::decode_header(token).map_err(|e| AuthError::MalformedToken {
        reason: format!("failed to decode JWT header: {e}"),
    })?;

    header.kid.ok_or_else(|| AuthError::MalformedToken {
        reason: "JWT header missing 'kid' field".to_string(),
    })
}

/// Build a [`DecodingKey`] from a JWK's RSA components.
///
/// # Errors
///
/// Returns [`AuthError::InvalidKey`] if the key type is not RSA,
/// or if the modulus/exponent are missing or cannot be parsed.
pub fn decoding_key_from_jwk(jwk: &Jwk) -> Result<DecodingKey, AuthError> {
    if jwk.kty != "RSA" {
        return Err(AuthError::InvalidKey {
            reason: format!("unsupported key type: {}", jwk.kty),
        });
    }

    let n = jwk.n.as_deref().ok_or_else(|| AuthError::InvalidKey {
        reason: "JWK missing RSA modulus (n)".to_string(),
    })?;

    let e = jwk.e.as_deref().ok_or_else(|| AuthError::InvalidKey {
        reason: "JWK missing RSA exponent (e)".to_string(),
    })?;

    // Decode base64url to raw bytes for from_rsa_raw_components
    let n_bytes = URL_SAFE_NO_PAD
        .decode(n)
        .map_err(|err| AuthError::InvalidKey {
            reason: format!("failed to decode RSA modulus: {err}"),
        })?;

    let e_bytes = URL_SAFE_NO_PAD
        .decode(e)
        .map_err(|err| AuthError::InvalidKey {
            reason: format!("failed to decode RSA exponent: {err}"),
        })?;

    Ok(DecodingKey::from_rsa_raw_components(&n_bytes, &e_bytes))
}

/// Verify and decode a Clerk JWT using the provided JWKS.
///
/// Performs full RS256 signature verification, expiration checking,
/// and claim extraction.
///
/// # Arguments
///
/// * `token` — The raw JWT string (without the `Bearer ` prefix).
/// * `jwks` — The JWKS fetched from Clerk's endpoint.
///
/// # Errors
///
/// Returns an [`AuthError`] variant for each failure mode:
/// - [`AuthError::MalformedToken`] — token cannot be parsed
/// - [`AuthError::KeyNotFound`] — no matching `kid` in the JWKS
/// - [`AuthError::InvalidKey`] — the JWK cannot be used for decoding
/// - [`AuthError::TokenExpired`] — the token has expired
/// - [`AuthError::InvalidSignature`] — signature verification failed
pub fn verify_token(token: &str, jwks: &JwkSet) -> Result<AuthClaims, AuthError> {
    let kid = extract_kid_from_token(token)?;

    let jwk = jwks
        .find(&kid)
        .ok_or_else(|| AuthError::KeyNotFound { kid: kid.clone() })?;

    let decoding_key = decoding_key_from_jwk(jwk)?;

    let mut validation = Validation::new(Algorithm::RS256);
    validation.validate_exp = true;
    validation.validate_nbf = true;
    // Clerk tokens may not always include an audience claim, so we
    // disable audience validation to avoid rejecting valid tokens.
    validation.validate_aud = false;

    let token_data =
        decode::<AuthClaims>(token, &decoding_key, &validation).map_err(|e| match e.kind() {
            jsonwebtoken::errors::ErrorKind::ExpiredSignature => AuthError::TokenExpired,
            jsonwebtoken::errors::ErrorKind::InvalidSignature => AuthError::InvalidSignature,
            jsonwebtoken::errors::ErrorKind::ImmatureSignature => AuthError::TokenNotYetValid,
            other => AuthError::VerificationFailed {
                reason: format!("{other:?}"),
            },
        })?;

    Ok(token_data.claims)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn jwk_set_find_returns_matching_key() {
        let jwks = JwkSet {
            keys: vec![
                Jwk {
                    kty: "RSA".to_string(),
                    kid: Some("key-1".to_string()),
                    n: Some("abc".to_string()),
                    e: Some("AQAB".to_string()),
                    alg: Some("RS256".to_string()),
                    use_: Some("sig".to_string()),
                },
                Jwk {
                    kty: "RSA".to_string(),
                    kid: Some("key-2".to_string()),
                    n: Some("def".to_string()),
                    e: Some("AQAB".to_string()),
                    alg: Some("RS256".to_string()),
                    use_: Some("sig".to_string()),
                },
            ],
        };

        let found = jwks.find("key-2");
        assert!(found.is_some());
        assert_eq!(found.map(|k| k.n.as_deref()), Some(Some("def")));
    }

    #[test]
    fn jwk_set_find_returns_none_for_missing_kid() {
        let jwks = JwkSet {
            keys: vec![Jwk {
                kty: "RSA".to_string(),
                kid: Some("key-1".to_string()),
                n: Some("abc".to_string()),
                e: Some("AQAB".to_string()),
                alg: Some("RS256".to_string()),
                use_: Some("sig".to_string()),
            }],
        };

        assert!(jwks.find("nonexistent").is_none());
    }

    #[test]
    fn decoding_key_from_jwk_rejects_non_rsa() {
        let jwk = Jwk {
            kty: "EC".to_string(),
            kid: Some("ec-key".to_string()),
            n: None,
            e: None,
            alg: Some("ES256".to_string()),
            use_: Some("sig".to_string()),
        };

        let result = decoding_key_from_jwk(&jwk);
        assert!(result.is_err());
        match result {
            Err(AuthError::InvalidKey { reason }) => {
                assert!(reason.contains("unsupported key type"));
            }
            other => panic!("expected InvalidKey, got: {other:?}"),
        }
    }

    #[test]
    fn decoding_key_from_jwk_rejects_missing_modulus() {
        let jwk = Jwk {
            kty: "RSA".to_string(),
            kid: Some("rsa-key".to_string()),
            n: None,
            e: Some("AQAB".to_string()),
            alg: Some("RS256".to_string()),
            use_: Some("sig".to_string()),
        };

        let result = decoding_key_from_jwk(&jwk);
        assert!(result.is_err());
        match result {
            Err(AuthError::InvalidKey { reason }) => {
                assert!(reason.contains("modulus"));
            }
            other => panic!("expected InvalidKey, got: {other:?}"),
        }
    }

    #[test]
    fn decoding_key_from_jwk_rejects_missing_exponent() {
        let jwk = Jwk {
            kty: "RSA".to_string(),
            kid: Some("rsa-key".to_string()),
            n: Some("abc".to_string()),
            e: None,
            alg: Some("RS256".to_string()),
            use_: Some("sig".to_string()),
        };

        let result = decoding_key_from_jwk(&jwk);
        assert!(result.is_err());
        match result {
            Err(AuthError::InvalidKey { reason }) => {
                assert!(reason.contains("exponent"));
            }
            other => panic!("expected InvalidKey, got: {other:?}"),
        }
    }

    #[test]
    fn extract_kid_from_invalid_token_returns_error() {
        let result = extract_kid_from_token("not-a-valid-jwt");
        assert!(result.is_err());
        match result {
            Err(AuthError::MalformedToken { .. }) => {}
            other => panic!("expected MalformedToken, got: {other:?}"),
        }
    }

    #[test]
    fn verify_token_returns_key_not_found_for_unknown_kid() {
        // Build a minimal JWT header with kid = "unknown"
        // Header: {"alg":"RS256","kid":"unknown","typ":"JWT"}
        let header = URL_SAFE_NO_PAD.encode(r#"{"alg":"RS256","kid":"unknown","typ":"JWT"}"#);
        let payload = URL_SAFE_NO_PAD.encode(r#"{"sub":"user_123"}"#);
        let token = format!("{header}.{payload}.fake-signature");

        let jwks = JwkSet { keys: vec![] };

        let result = verify_token(&token, &jwks);
        assert!(result.is_err());
        match result {
            Err(AuthError::KeyNotFound { kid }) => {
                assert_eq!(kid, "unknown");
            }
            other => panic!("expected KeyNotFound, got: {other:?}"),
        }
    }

    #[test]
    fn auth_claims_deserializes_minimal_payload() {
        let json = r#"{"sub":"user_abc123"}"#;
        let claims: AuthClaims =
            serde_json::from_str(json).expect("should deserialize minimal claims");
        assert_eq!(claims.sub, "user_abc123");
        assert!(claims.iss.is_none());
        assert!(claims.exp.is_none());
    }

    #[test]
    fn auth_claims_deserializes_full_payload() {
        let json = r#"{
            "sub": "user_abc123",
            "iss": "https://clerk.example.com",
            "exp": 1700000000,
            "nbf": 1699999000,
            "iat": 1699999000,
            "jti": "jwt-id-123",
            "azp": "https://myapp.example.com",
            "sid": "sess_abc"
        }"#;
        let claims: AuthClaims =
            serde_json::from_str(json).expect("should deserialize full claims");
        assert_eq!(claims.sub, "user_abc123");
        assert_eq!(claims.iss.as_deref(), Some("https://clerk.example.com"));
        assert_eq!(claims.exp, Some(1700000000));
        assert_eq!(claims.sid.as_deref(), Some("sess_abc"));
    }

    #[test]
    fn auth_claims_serializes_roundtrip() {
        let claims = AuthClaims {
            sub: "user_test".to_string(),
            iss: Some("https://clerk.example.com".to_string()),
            exp: Some(1700000000),
            nbf: Some(1699999000),
            iat: Some(1699999000),
            jti: None,
            azp: None,
            sid: Some("sess_123".to_string()),
        };

        let json = serde_json::to_string(&claims).expect("should serialize");
        let roundtrip: AuthClaims = serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(claims, roundtrip);
    }
}
