# ADR-003: Authentication — Clerk with JWT Verification

**Status:** Accepted
**Date:** 2026-03-19
**Deciders:** Project team

## Context

Dishy needs user authentication to associate recipes with users and protect API endpoints. The system spans a Rust Cloudflare Worker backend and a Flutter mobile frontend, requiring a solution that works across both platforms.

Key requirements:
- Email/password sign-in (with social login later)
- JWT-based session tokens for stateless API authentication
- No server-side session storage (Workers are stateless)
- Integration with existing structured logging and correlation ID propagation

## Decision

### Provider: Clerk

Clerk provides a managed authentication service with:
- Flutter SDK (`clerk_flutter` ^0.0.14-beta) for mobile sign-in flows
- JWT session tokens signed with RS256 for backend verification
- JWKS endpoint for public key distribution
- Email/password, social login, and passwordless strategies

### Backend: JWT Verification via Web Crypto API

The Rust Worker verifies Clerk JWTs using the Web Crypto API (SubtleCrypto), which is natively available in the Cloudflare Workers runtime. This avoids pulling in native crypto crates (like `ring`) that don't compile to `wasm32-unknown-unknown`.

Verification flow:
1. Extract the Bearer token from the `Authorization` header.
2. Decode the JWT header to get the `kid` (Key ID).
3. Fetch the JWKS from Clerk's endpoint (`https://api.clerk.com/v1/jwks`).
4. Import the matching RSA public key via `crypto.subtle.importKey`.
5. Verify the RS256 signature via `crypto.subtle.verify`.
6. Validate claims: `exp` (with 60s leeway), `iat`, and `sub`.

### Error Handling

Authentication errors use typed `AuthError` variants (via `thiserror`) that map to JSON error responses:

```json
{ "error": { "code": "auth_token_expired", "message": "JWT has expired" } }
```

All auth failures return HTTP 401 with a machine-readable `code` and human-readable `message`.

### Frontend: Riverpod State Management

Authentication state is managed via a `StateNotifier<AuthState>` where `AuthState` is a sealed class hierarchy:
- `AuthLoading` — initialising
- `AuthAuthenticated` — signed in with userId and optional email
- `AuthUnauthenticated` — no valid session
- `AuthError` — authentication failed

A `GoRouter` redirect guard checks auth state and sends unauthenticated users to the sign-in screen.

The API client has two interceptors (in order):
1. `AuthInterceptor` — attaches the Bearer token from the auth notifier.
2. `CorrelationInterceptor` — attaches `X-Correlation-ID` and `X-Session-ID` headers and logs the request lifecycle.

### Logging Integration

All authentication events are logged through the existing structured logging pipeline:
- **Backend:** `authenticate_request()` logs success/failure with user ID or error code via the `RequestContext.logger`.
- **Frontend:** `AuthNotifier` logs state transitions via `LogService`.

Auth logs carry the same correlation and session IDs as all other logs, enabling end-to-end tracing in Axiom.

### Configuration

| Variable | Location | Type |
|----------|----------|------|
| `CLERK_PUBLISHABLE_KEY` | `wrangler.toml` [vars], Flutter `--dart-define` | Public |
| `CLERK_JWKS_URL` | `wrangler.toml` [vars] | Public |
| `CLERK_SECRET_KEY` | Cloudflare secret | Secret |

## Consequences

### Positive

- **Stateless authentication:** JWT verification requires no server-side session storage, which aligns with the Workers execution model.
- **Managed auth:** Clerk handles user management, password hashing, email verification, and session lifecycle — reducing implementation surface.
- **WASM-compatible crypto:** Using the Web Crypto API avoids native crate compilation issues on `wasm32-unknown-unknown`.
- **Integrated observability:** Auth events flow through the same Axiom pipeline as all other logs.
- **Type-safe error handling:** `thiserror` enums with exhaustive matching prevent unhandled auth failures.

### Negative

- **Clerk dependency:** A managed auth provider creates vendor lock-in. Migration would require replacing JWT issuance and the Flutter SDK.
- **Beta SDK:** The `clerk_flutter` package is in beta (0.0.14-beta). Breaking changes are possible before 1.0.
- **JWKS fetch latency:** Every authenticated request fetches the JWKS from Clerk's API. This should be cached in a future iteration (with TTL-based invalidation).

### Risks

- If Clerk changes their JWT claims structure, the `AuthClaims` struct and validation logic need updating.
- The beta Flutter SDK may have bugs or missing features. Fallback: use `clerk_auth` (Dart) directly.
- JWKS caching is deferred — high-traffic endpoints will make redundant JWKS fetches until caching is implemented.

## References

- [Clerk JWT Verification](https://clerk.com/docs/backend-requests/handling/manual-jwt)
- [Web Crypto API](https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto)
- [Cloudflare Workers Crypto](https://developers.cloudflare.com/workers/runtime-apis/web-crypto/)
- [ADR-001: Tech Stack Selection](001-tech-stack.md)
- [ADR-002: Observability](002-observability.md)
