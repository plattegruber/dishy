# Dishy

Recipe Capture & Cooking App. Convert messy, ephemeral food content into structured, beautiful, usable recipes with minimal effort.

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Rust | stable | [rustup.rs](https://rustup.rs/) |
| wasm32-unknown-unknown target | — | `rustup target add wasm32-unknown-unknown` |
| worker-build | latest | `cargo install worker-build` |
| Node.js | 18+ | [nodejs.org](https://nodejs.org/) |
| Wrangler | latest | `npm install -g wrangler` (or use `npx wrangler`) |
| Flutter | stable (3.x) | [flutter.dev/get-started](https://docs.flutter.dev/get-started/install) |

## Project Structure

```
/
├── SPEC.md                     # Product specification
├── CLAUDE.md                   # Project intelligence for AI assistants
├── docs/adr/                   # Architecture Decision Records
├── apps/
│   ├── api/                    # Cloudflare Worker (Rust)
│   │   ├── src/
│   │   │   ├── lib.rs          # Worker entry point & routes
│   │   │   ├── auth.rs         # JWT verification (Clerk JWKS)
│   │   │   ├── errors.rs       # Structured error types
│   │   │   └── middleware/     # Auth middleware
│   │   ├── tests/              # Rust tests
│   │   ├── Cargo.toml          # Rust dependencies
│   │   └── wrangler.toml       # Cloudflare Worker config
│   └── mobile/                 # Flutter app (iOS + Android)
│       ├── lib/
│       │   ├── main.dart       # App entry point
│       │   ├── app.dart        # MaterialApp + GoRouter setup
│       │   ├── core/auth/      # Auth state, provider, guard
│       │   ├── presentation/   # Screens, widgets, providers
│       │   ├── domain/         # Entities, use cases
│       │   ├── data/           # Repositories, API client
│       │   └── core/           # Constants, utilities
│       ├── test/               # Widget & unit tests
│       └── pubspec.yaml        # Dart dependencies
└── .github/workflows/          # CI/CD pipelines
```

## Authentication Setup (Clerk)

Dishy uses [Clerk](https://clerk.com) for authentication. See [ADR-003](docs/adr/003-authentication.md) for the full rationale.

### 1. Create a Clerk Application

1. Sign up at [clerk.com](https://clerk.com) and create a new application
2. Enable **Email/Password** as a sign-in method
3. Copy your **Publishable Key** (starts with `pk_test_` or `pk_live_`)

### 2. Configure the API (Cloudflare Worker)

Update `apps/api/wrangler.toml` with your publishable key:

```toml
[vars]
CLERK_PUBLISHABLE_KEY = "pk_test_your_key_here"
CLERK_JWKS_URL = "https://api.clerk.com/v1/jwks"
```

Set the secret key (never committed to source):

```bash
cd apps/api
npx wrangler secret put CLERK_SECRET_KEY
# Paste your Clerk Secret Key when prompted
```

### 3. Configure the Flutter App

Pass your Clerk publishable key when running the app:

```bash
cd apps/mobile
flutter run --dart-define=CLERK_PUBLISHABLE_KEY=pk_test_your_key_here
```

Or for local development with the API:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://localhost:8787 \
  --dart-define=CLERK_PUBLISHABLE_KEY=pk_test_your_key_here
```

### API Endpoints

| Endpoint | Auth | Description |
|----------|------|-------------|
| `GET /health` | No | Health check — returns API status and version |
| `GET /me` | Yes | Returns the authenticated user's identity from the JWT |

## API (Cloudflare Worker — Rust)

### Setup

```bash
cd apps/api

# Build the project
cargo build

# Run tests
cargo test

# Start local dev server (requires wrangler)
npx wrangler dev
```

The local dev server runs at `http://localhost:8787`. Test the health endpoint:

```bash
curl http://localhost:8787/health
# → {"status":"ok","version":"0.1.0"}
```

Test the authenticated `/me` endpoint:

```bash
curl -H "Authorization: Bearer <your-clerk-jwt>" http://localhost:8787/me
# → {"user_id":"user_xxx","issuer":"https://...","session_id":"sess_xxx"}
```

### Linting

```bash
cargo fmt --check    # Check formatting
cargo clippy -- -D warnings   # Lint with warnings as errors
```

## Mobile (Flutter)

### Setup

```bash
cd apps/mobile

# Install dependencies
flutter pub get

# Run code generation (freezed, json_serializable, riverpod_generator)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### Testing

```bash
flutter test         # Run all tests
flutter analyze      # Static analysis
```

### Build

```bash
flutter build apk --debug     # Android debug build
flutter build ios --debug      # iOS debug build (macOS only)
```

### Pointing to Local API

When running the API locally with `wrangler dev`, pass the local URL:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8787
```

## Running All Tests

```bash
# API tests
(cd apps/api && cargo test)

# Mobile tests
(cd apps/mobile && flutter test)
```

## CI/CD

- **API CI** (`api.yml`): Runs on PRs and pushes to `main` affecting `apps/api/`. Checks formatting, clippy, tests, and builds the Worker.
- **Mobile CI** (`mobile.yml`): Runs on PRs and pushes to `main` affecting `apps/mobile/`. Runs analyze, tests, and a debug APK build.
- **Deploy API** (`deploy-api.yml`): On merge to `main`, builds and deploys the Worker to Cloudflare. Requires `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` secrets.

## Documentation

- [Product Specification](SPEC.md)
- [Project Intelligence](CLAUDE.md)
- [ADR-001: Tech Stack Selection](docs/adr/001-tech-stack.md)
- [ADR-003: Authentication](docs/adr/003-authentication.md)
