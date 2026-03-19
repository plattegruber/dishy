# Dishy — Project Intelligence

## Product

Recipe Capture & Cooking App. See SPEC.md for the authoritative specification.

## Stack

- **API Runtime:** Cloudflare Workers (Rust via `workers-rs` crate)
- **Database:** Cloudflare D1 (SQLite, accessed via workers-rs D1 bindings)
- **File Storage:** Cloudflare R2 (images, capture artifacts)
- **Async Pipeline:** Cloudflare Queues (capture → extract → structure pipeline)
- **Frontend/Mobile:** Flutter (iOS + Android, mobile + tablet)
- **State Management:** Riverpod 3.x
- **Auth:** Clerk (Flutter SDK + backend JWT verification on Workers)
- **AI:** Anthropic Claude API (extraction, structuring)
- **Logging/Observability:** Axiom
- **Nutrition:** USDA FoodData Central (primary, free) + Edamam (fallback, free tier)
- **CI/CD:** GitHub Actions + Fastlane (TestFlight + Google Play Console)
- **CLI:** `npx wrangler` — never assume a global `wrangler` install

## Documentation Policy — MANDATORY

Before implementing any integration with an external service or Cloudflare
primitive, fetch the current official documentation. Do not rely on training
data. APIs, SDK shapes, and config syntax change frequently.

Required fetches before first use:

- Cloudflare Workers (Rust): https://developers.cloudflare.com/workers/languages/rust/
- workers-rs crate: https://github.com/cloudflare/workers-rs
- Cloudflare D1: https://developers.cloudflare.com/d1/
- Cloudflare R2: https://developers.cloudflare.com/r2/
- Cloudflare Queues: https://developers.cloudflare.com/queues/
- Flutter: https://docs.flutter.dev/
- Riverpod: https://riverpod.dev/docs/introduction/getting-started
- Clerk Flutter: https://clerk.com/docs
- Anthropic API: https://docs.anthropic.com/en/api
- Axiom: https://axiom.co/docs
- USDA FoodData Central: https://fdc.nal.usda.gov/api-guide
- Fastlane: https://docs.fastlane.tools/

If documentation contradicts your training data, documentation wins.
If you are unsure of the current shape of any API or config option,
fetch the docs before writing code. Never guess.

## Architecture — Monorepo Structure

```
/
├── SPEC.md
├── CLAUDE.md
├── README.md
├── docs/
│   └── adr/                    # Architecture Decision Records
├── apps/
│   ├── api/                    # Cloudflare Worker — Rust
│   │   ├── src/
│   │   │   ├── lib.rs          # Worker entry point
│   │   │   ├── routes/         # One file per SPEC section
│   │   │   ├── services/       # Business logic per SPEC component
│   │   │   ├── db/             # D1 queries and migrations
│   │   │   ├── pipeline/       # Capture → Extract → Structure stages
│   │   │   └── types/          # Domain types from SPEC §8
│   │   ├── tests/
│   │   ├── Cargo.toml
│   │   └── wrangler.toml
│   └── mobile/                 # Flutter app
│       ├── lib/
│       │   ├── main.dart
│       │   ├── presentation/   # Screens, widgets, Riverpod providers
│       │   ├── domain/         # Entities, use cases (SPEC domain model)
│       │   ├── data/           # Repositories, API client, DTOs
│       │   └── core/           # Constants, utils, error handling
│       ├── test/
│       ├── integration_test/
│       ├── ios/
│       ├── android/
│       ├── pubspec.yaml
│       └── fastlane/
└── .github/
    └── workflows/              # CI/CD pipelines
```

## Architecture — Cloudflare Service Mapping

| SPEC Component             | Cloudflare Primitive        |
| -------------------------- | --------------------------- |
| API core                   | Workers (Rust, workers-rs)  |
| All entity persistence     | D1 (SQLite)                 |
| Image/artifact storage     | R2                          |
| Capture pipeline jobs      | Queues (consumer Workers)   |
| Extraction pipeline jobs   | Queues (consumer Workers)   |
| Auth session verification  | Clerk JWT middleware        |

## Build Pipeline — Rust Workers

- Rust compiles to `wasm32-unknown-unknown` target
- `worker-build` creates JS entrypoint + WASM bundle for Wrangler
- Release optimizations in Cargo.toml: `lto = true`, `strip = true`, `codegen-units = 1`
- Feature flags: `worker = { features = ["http", "d1", "queue"] }`

## Workflow — Walking Skeleton PRs

Every PR must be a **walking skeleton**: a thin vertical slice that is fully
complete from top to bottom. Even if the change is trivially small (e.g. adding
a single field), the PR must include:

1. The code change itself.
2. Comprehensive test coverage (unit tests; acceptance/integration if needed).
3. Updated documentation (README, inline docs, ADRs as appropriate).
4. Updated CI/CD configuration if affected.
5. Updated local dev setup instructions if affected.

No partial slices. No "tests in a follow-up." Ship it whole or don't ship it.

## Workflow — Definition of Done

A task is NOT done until ALL of the following are true:

1. Code is on a feature branch with passing tests locally.
2. PR is opened with a clear title and description.
3. All PR checks pass (lint, typecheck, tests).
4. PR is merged to `main`.
5. CI/CD succeeds on `main`.
6. The user is told to try it out.

**Workflow obligation:** When told to "do this thing," drive through the entire
pipeline automatically: implement → commit → push → open PR → watch checks
pass → merge → watch CI/CD → report back. The user should never have to prompt
you to continue the delivery pipeline. Finishing the code is the midpoint, not
the end.

## Workflow — Agent Teams

Strong preference for [Agent Teams](https://code.claude.com/docs/en/agent-teams).
The main conversation context must stay free for discussion. Claude acts as the
**manager/orchestrator**, rarely as the direct executor:

- Delegate implementation work to subagents.
- Use the main context for planning, status updates, and decisions.
- Only execute directly for trivially small changes where spinning up an agent
  would cost more than doing it inline.

## Documentation & Logging Policy

In these early days, over-invest in documentation and logging:

- Every new module, service, or pipeline stage gets a doc comment explaining
  what it does and why it exists.
- Log at key pipeline transitions with structured, meaningful messages.
- Send structured logs to Axiom for all pipeline stages.
- Maintain a living ADR (Architecture Decision Record) log in `docs/adr/`.
- README must always reflect the current state of local dev setup.

## Code Style — Rust (API)

- No `unsafe` unless absolutely necessary and documented with a safety comment.
- No `.unwrap()` in production code. Use `Result<T, E>` and propagate errors.
- Use `thiserror` for error types; structured errors, not string messages.
- All public items get doc comments (`///`).
- `clippy` with `--deny warnings` in CI.
- `rustfmt` enforced in CI.

## Code Style — Dart/Flutter (Mobile)

- Analysis options: use `flutter_lints` or stricter.
- No `dynamic` types. This is the Dart equivalent of `any` — solve the type.
- No force-unwrapping (`!`) on nullables. Handle null explicitly.
- Prefer immutable state (Riverpod + `freezed` for data classes).
- Use `json_serializable` + `freezed` for codegen, not manual serialization.
- Use `go_router` for navigation.

## Testing

### Rust (API)
- Framework: `cargo test` + `wasm-bindgen-test` for Workers-specific code.
- All public functions in `services/` and `pipeline/` must have tests.
- Integration tests use Miniflare or `wrangler dev --test`.
- `cargo clippy` and `cargo fmt --check` in CI.

### Flutter (Mobile)
- Unit tests for domain logic and repositories.
- Widget tests for UI components.
- Integration tests for critical flows (recipe capture, cooking mode).
- Use `mockito` for mocking API calls in tests.
- `flutter test` and `flutter analyze` in CI.

### Coverage
- Minimum coverage threshold: 80% lines (enforced in CI for both Rust and Flutter).

## Git

- Main branch: `main` — protected, no direct pushes.
- Feature branches: `feat/{scope}`, `fix/{scope}`, `docs/{scope}`, `chore/{scope}`
- All changes land via PR.
- PR title format: `feat(scope): description` or `fix(scope): description`
- Commit messages follow Conventional Commits.
- `gh` CLI is available and authenticated.

## PR Checks

All PRs must have passing checks before merge. Required checks:

### API (Rust)
- `cargo fmt --check`
- `cargo clippy -- -D warnings`
- `cargo test`
- `worker-build --release`

### Mobile (Flutter)
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug` (build check)

Do not merge with failing checks. Do not skip checks.

## CI/CD — Deployment

### API
- On merge to `main`: `wrangler deploy` to Cloudflare Workers.

### Mobile
- Fastlane manages code signing (Match for iOS) and store uploads.
- iOS: Fastlane Match for certificates → `flutter build ipa` → upload to TestFlight.
- Android: Keystore signing → `flutter build appbundle` → upload to Play Console (internal track).
- GitHub Actions uses `subosito/flutter-action` for Flutter setup.
- GitHub Actions uses `ruby/setup-ruby` + bundled Fastlane for mobile deploys.

## Environment and Secrets

- Cloudflare secrets via `npx wrangler secret put` (never in source).
- No secrets in `.env` files committed to the repo.
- GitHub Secrets for CI/CD: Cloudflare API token, Fastlane Match password,
  iOS App Store Connect API key, Android keystore + Play Console service account.
- Required Cloudflare bindings declared in `wrangler.toml` and typed in Rust.

## External Service Notes

### Nutrition (USDA FoodData Central)
- Free, no auth required (just a data.gov API key).
- Rate limit: 1,000 req/hr.
- Use for standard ingredient lookups.
- Edamam free tier (400 req/mo) as fallback for natural language ingredient parsing.

### Anthropic Claude API
- Used for recipe extraction from unstructured content (OCR text, transcripts, screenshots).
- Used for structuring raw extraction into recipe candidates.
- Always use structured output / tool use for deterministic parsing.
