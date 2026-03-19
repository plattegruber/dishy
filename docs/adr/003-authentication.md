# ADR-003: Authentication — Clerk with JWT Verification

## Status

Accepted

## Context

Dishy needs user authentication to:
- Associate captured recipes with individual users
- Protect API endpoints from unauthorized access
- Enable personalisation (favorites, notes, patches)

We need a solution that works across both the Flutter mobile app and the Cloudflare Worker (Rust) backend with minimal operational burden.

## Decision

We chose **Clerk** as the authentication provider with **JWT verification on the backend**.

### Architecture

```
Flutter App (clerk_auth SDK)
  |
  | Bearer <JWT>
  v
Cloudflare Worker (Rust)
  |
  | Verify JWT signature using JWKS
  v
Route handlers receive typed AuthClaims
```

### Frontend (Flutter)

- **Package:** `clerk_auth` (0.0.14-beta) — the Dart-only SDK from Clerk
- **State management:** A `StateNotifier<AuthState>` Riverpod provider wraps the Clerk SDK
- **Auth state model:** Sealed class hierarchy (`AuthLoading`, `AuthUnauthenticated`, `AuthAuthenticated`, `AuthError`) — no `dynamic` types
- **Token attachment:** Dio interceptor automatically adds `Authorization: Bearer <token>` to all API requests
- **401 handling:** Dio error interceptor detects 401 responses and triggers re-authentication
- **Route protection:** GoRouter redirect guard sends unauthenticated users to the sign-in screen

We use `clerk_auth` (the Dart-only package) rather than `clerk_flutter` (the full UI package) because:
1. `clerk_flutter` pulls in heavy platform dependencies (webview, image_picker) that complicate CI
2. The SDK is still in beta (0.0.14-beta); the lighter package reduces surface area for breaking changes
3. We build our own sign-in UI, which gives us full control over the UX

### Backend (Rust Worker)

- **JWT library:** `jsonwebtoken` (10.x) for RS256 signature verification
- **JWKS source:** Clerk's `https://api.clerk.com/v1/jwks` endpoint provides RSA public keys
- **Verification flow:**
  1. Extract `kid` from the JWT header (without verifying the signature)
  2. Look up the matching key in the JWKS by `kid`
  3. Build a `DecodingKey` from the JWK's RSA modulus and exponent
  4. Verify the RS256 signature, expiration (`exp`), and not-before (`nbf`) claims
  5. Extract typed `AuthClaims` (sub, iss, exp, nbf, azp, sid, etc.)
- **Error handling:** Structured `AuthError` enum with `thiserror` — no `.unwrap()`, no string-only errors
- **Error responses:** All auth failures return 401 with a JSON body containing a machine-readable `error` code and human-readable `message`

### Key Rotation

Clerk rotates JWKS keys infrequently. Currently, we fetch JWKS on each authenticated request. A future improvement is to cache JWKS in the Worker's memory with a short TTL (e.g. 5 minutes), falling back to a fresh fetch on cache miss or `kid` mismatch.

### Configuration

| Setting | Location | Type |
|---------|----------|------|
| `CLERK_PUBLISHABLE_KEY` | `wrangler.toml` vars / Flutter `--dart-define` | Public (safe in source) |
| `CLERK_SECRET_KEY` | `npx wrangler secret put` | Secret (never in source) |
| `CLERK_JWKS_URL` | `wrangler.toml` vars | Public |

## Alternatives Considered

### Firebase Auth
- Pros: Mature Flutter SDK, generous free tier
- Cons: Google ecosystem lock-in, more complex JWT verification for non-Firebase backends, doesn't integrate well with Cloudflare Workers

### Supabase Auth
- Pros: Open source, good Flutter SDK
- Cons: Requires running a Supabase instance or using their hosted service, adds another infrastructure dependency alongside Cloudflare

### Custom auth (roll our own)
- Pros: Full control
- Cons: Significant security risk, maintenance burden for password hashing, token management, email verification, etc.

### Auth0
- Pros: Enterprise-grade, extensive SDK support
- Cons: More complex pricing, heavier SDK, overkill for a recipe app

## Consequences

### Positive
- Single sign-in experience across iOS and Android
- JWT verification on Workers is stateless — no session store needed
- Clerk handles password hashing, email verification, and token rotation
- Clean separation: frontend owns the auth flow, backend only verifies JWTs
- Structured error types make debugging auth failures straightforward

### Negative
- Dependency on Clerk's beta Flutter SDK — API may change before 1.0
- JWKS fetch on every request adds latency (mitigated by planned caching)
- Clerk is a paid service beyond the free tier (10K MAU)

### Risks
- If the `clerk_auth` package introduces breaking changes, our thin adapter layer limits blast radius to `auth_provider.dart`
- If Clerk has an outage, new sign-ins fail but existing JWTs continue to verify until they expire
