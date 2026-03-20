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
│   │   │   ├── auth.rs         # Clerk JWT verification (RS256 via Web Crypto)
│   │   │   ├── errors.rs       # Typed auth & API error responses
│   │   │   ├── logging.rs      # Structured logging & Axiom transport
│   │   │   ├── middleware.rs   # Correlation IDs, auth extraction, logging context
│   │   │   ├── services/       # Business logic (extraction, nutrition, storage, cover)
│   │   │   ├── types/          # Domain types from SPEC §8
│   │   │   ├── db/             # D1 database schema, migrations, queries
│   │   │   └── pipeline/       # Capture pipeline contracts (SPEC §9)
│   │   ├── tests/              # Rust tests
│   │   ├── Cargo.toml          # Rust dependencies
│   │   └── wrangler.toml       # Cloudflare Worker config
│   └── mobile/                 # Flutter app (iOS + Android)
│       ├── lib/
│       │   ├── main.dart       # App entry point (Clerk initialisation)
│       │   ├── app.dart        # MaterialApp + GoRouter + auth guard
│       │   ├── presentation/   # Screens, widgets, providers
│       │   ├── domain/         # Domain model (freezed types mirroring SPEC §8)
│       │   ├── data/           # Repositories, API client (auth + correlation interceptors)
│       │   └── core/
│       │       ├── auth/       # Auth state, provider, guard
│       │       ├── constants/  # App-wide configuration
│       │       └── logging/    # Structured logging, Axiom transport, correlation providers
│       ├── test/               # Widget & unit tests
│       └── pubspec.yaml        # Dart dependencies
└── .github/workflows/          # CI/CD pipelines
```

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

### Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/health` | No | Health check -- returns `{"status":"ok","version":"..."}` |
| GET | `/me` | Yes | Returns authenticated user's claims from the JWT |
| POST | `/recipes/capture` | Yes | Capture recipe from text via Claude extraction |
| GET | `/recipes` | Yes | List all recipes for the authenticated user |
| GET | `/recipes/:id` | Yes | Get a single recipe by ID |
| GET | `/recipes/:id/nutrition` | Yes | Detailed nutrition breakdown per ingredient |
| POST | `/recipes/:id/cover` | Yes | Upload a cover image for a recipe (JPEG/PNG/WebP, max 10 MB) |
| GET | `/images/:asset_id` | No | Serve an image from R2 with cache headers |

### Recipe Capture

The capture endpoint accepts manual text input and runs the full extraction pipeline:

```bash
curl -X POST http://localhost:8787/recipes/capture \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"input_type": "manual", "text": "Chocolate Cake\n\nIngredients:\n2 cups flour\n1 cup sugar\n\nSteps:\n1. Preheat oven\n2. Mix and bake"}'
```

The pipeline stages:
1. Save capture input to D1
2. Call Claude API with tool_use for structured extraction
3. Parse ingredients via Claude API (tool_use for structured parsing)
4. Resolve ingredients against USDA FoodData Central
5. Compute nutrition from resolved ingredients (per-recipe and per-serving)
6. Generate cover (SVG placeholder via R2, or source image if uploaded)
7. Assemble and save recipe to D1
8. Return the saved `ResolvedRecipe`

**Required secrets:**
```bash
npx wrangler secret put ANTHROPIC_API_KEY
npx wrangler secret put FDC_API_KEY  # Free key from https://api.data.gov/signup/
```

**Note:** The FDC_API_KEY is optional. Without it, ingredient resolution and nutrition computation are skipped (status: unavailable). The pipeline degrades gracefully.

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

## Authentication

Dishy uses [Clerk](https://clerk.com) for authentication. The Flutter app uses the `clerk_flutter` SDK for sign-in flows, and the Rust Worker verifies Clerk-issued JWTs using RS256 signature verification via the Web Crypto API.

### Setup

1. Create a Clerk application at [dashboard.clerk.com](https://dashboard.clerk.com).
2. Enable the Email/Password sign-in strategy.
3. Copy your keys:

**API (Cloudflare Worker):**

```bash
# Set the Clerk secret key
npx wrangler secret put CLERK_SECRET_KEY
```

Update `wrangler.toml` with your JWKS URL and publishable key:

```toml
[vars]
CLERK_JWKS_URL = "https://api.clerk.com/v1/jwks"
CLERK_PUBLISHABLE_KEY = "pk_test_your-key-here"
```

**Mobile (Flutter):**

```bash
flutter run --dart-define=CLERK_PUBLISHABLE_KEY=pk_test_your-key-here
```

### Auth Flow

1. User opens the app and sees the sign-in screen (unauthenticated).
2. User signs in via Clerk (email/password).
3. Clerk issues a JWT session token.
4. The mobile app attaches the token as `Authorization: Bearer <token>` to all API requests.
5. The Worker verifies the JWT against Clerk's JWKS and extracts user claims.
6. All auth events are logged through the structured logging pipeline for observability.

See [ADR-003: Authentication](docs/adr/003-authentication.md) for the full design rationale.

## Database (Cloudflare D1)

The API uses Cloudflare D1 (SQLite) for all entity persistence. The schema is defined in `apps/api/src/db/schema.sql` with migrations in `apps/api/src/db/migrations/`.

### Setup

```bash
# Create the D1 database (one-time)
npx wrangler d1 create dishy-db

# Update wrangler.toml with the database_id from the output above

# Apply migrations locally
npx wrangler d1 migrations apply DB --local

# Apply migrations to production
npx wrangler d1 migrations apply DB --remote
```

### Tables

| Table | Purpose |
|-------|---------|
| `capture_inputs` | Raw user input that initiated the capture pipeline |
| `extraction_artifacts` | Versioned extraction results (never overwritten) |
| `recipes` | Canonical resolved recipes |
| `recipe_ingredients` | Resolved ingredients for each recipe |
| `recipe_steps` | Ordered instruction steps for each recipe |
| `user_recipe_views` | Per-user overlay (saves, favorites, notes, patches) |

See [ADR-004: Domain Model](docs/adr/004-domain-model.md) for the full schema design rationale.

## Image Storage (Cloudflare R2)

Recipe cover images are stored in Cloudflare R2. The API generates deterministic SVG placeholders for recipes without uploaded images.

### Setup

```bash
# Create the R2 bucket (one-time)
npx wrangler r2 bucket create dishy-images
```

The `IMAGES` binding is already configured in `wrangler.toml`.

### Cover Image Flow

1. **During capture:** An SVG placeholder is generated from the recipe title (deterministic color + initial) and uploaded to R2.
2. **User upload:** `POST /recipes/:id/cover` accepts JPEG/PNG/WebP images (max 10 MB) and stores them in R2.
3. **Serving:** `GET /images/:asset_id` serves images from R2 with a 1-year cache (immutable assets).
4. **Fallback:** The mobile app shows a local color placeholder matching the server-side SVG while the image loads.

See [ADR-007: Cover Image Generation](docs/adr/007-cover-image-generation.md) for the full design rationale.

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
- **Deploy API** (`deploy-api.yml`): On merge to `main`, builds and deploys the Worker to Cloudflare. Requires `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, and `AXIOM_API_TOKEN` secrets.

## Observability

Structured JSON logs are sent to [Axiom](https://axiom.co) from both the API and mobile app. Every HTTP request carries an `X-Correlation-ID` (UUIDv4, generated per request) and `X-Session-ID` (UUIDv4, generated per app session) header, linking frontend and backend logs.

- **Backend:** Logs are buffered per request and flushed to the `dishy-api` Axiom dataset. The `AXIOM_API_TOKEN` secret must be set via `npx wrangler secret put AXIOM_API_TOKEN`.
- **Frontend:** Logs are batched and sent to the `dishy-mobile` Axiom dataset. Pass the token at build time: `--dart-define=AXIOM_API_TOKEN=<token>`.

See [ADR-002: Observability](docs/adr/002-observability.md) for the full design rationale.

## Documentation

- [Product Specification](SPEC.md)
- [Project Intelligence](CLAUDE.md)
- [ADR-001: Tech Stack Selection](docs/adr/001-tech-stack.md)
- [ADR-002: Observability](docs/adr/002-observability.md)
- [ADR-003: Authentication](docs/adr/003-authentication.md)
- [ADR-004: Domain Model](docs/adr/004-domain-model.md)
- [ADR-005: Capture Pipeline](docs/adr/005-capture-pipeline.md)
- [ADR-006: Ingredient & Nutrition Pipeline](docs/adr/006-ingredient-nutrition-pipeline.md)
- [ADR-007: Cover Image Generation](docs/adr/007-cover-image-generation.md)
