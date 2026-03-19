# ADR-001: Tech Stack Selection

**Status:** Accepted
**Date:** 2026-03-19
**Deciders:** Project team

## Context

Dishy is a recipe capture and cooking app that converts messy, ephemeral food content (social media posts, screenshots, speech) into structured, beautiful, usable recipes. The system is a long-lived data pipeline that must:

- Handle multi-modal input (images, text, audio, URLs)
- Run an async extraction/structuring pipeline with AI
- Serve a fast, responsive mobile experience on iOS and Android
- Scale cost-effectively from zero to thousands of users
- Keep infrastructure simple (small team, fast iteration)

We need to select a backend runtime, database, mobile framework, and supporting services that meet these constraints.

## Decision

### Backend: Cloudflare Workers (Rust via workers-rs)

- **Why Rust:** Type safety, zero-cost abstractions, excellent WASM compilation target, no garbage collection pauses. The `workers-rs` crate provides first-class Rust bindings for the Workers runtime.
- **Why Cloudflare Workers:** Edge-first, pay-per-request pricing (true scale-to-zero), integrated ecosystem (D1, R2, Queues) that eliminates the need to stitch together separate services.

### Database: Cloudflare D1 (SQLite)

- **Why D1:** Co-located with Workers for minimal latency. SQLite semantics are simple and predictable. Built-in read replicas. No connection pool management. Free tier is generous for early development.

### File Storage: Cloudflare R2

- **Why R2:** S3-compatible API with zero egress fees. Co-located with Workers. Ideal for recipe images, capture artifacts, and pipeline outputs.

### Async Pipeline: Cloudflare Queues

- **Why Queues:** Native integration with Workers. The capture-extract-structure pipeline is inherently async and benefits from decoupled stages. Built-in retries and dead-letter handling.

### Mobile: Flutter with Riverpod

- **Why Flutter:** Single codebase for iOS and Android. Strong typing with Dart. Fast development cycle with hot reload. Material 3 support for modern UI.
- **Why Riverpod:** Compile-time safe, testable, and supports code generation. Successor to Provider with better architecture patterns. Pairs well with `freezed` for immutable state and `go_router` for declarative navigation.

### Auth: Clerk

- **Why Clerk:** Drop-in authentication with Flutter SDK and backend JWT verification. Handles social login, email/password, and session management. Reduces auth implementation to configuration rather than code.

### AI: Anthropic Claude API

- **Why Claude:** Strong performance on structured extraction tasks. Tool use / structured output support enables deterministic parsing of recipes from unstructured content. Used for both extraction and structuring pipeline stages.

### Observability: Axiom

- **Why Axiom:** Structured logging with generous free tier. Simple HTTP-based ingestion from Workers. Query language for debugging pipeline issues.

### Nutrition: USDA FoodData Central + Edamam

- **Why USDA:** Free, authoritative, no authentication required (just an API key). 1,000 req/hr rate limit is sufficient for ingredient lookups.
- **Why Edamam:** Fallback for natural language ingredient parsing where USDA structured search falls short. Free tier (400 req/mo) covers edge cases.

### CI/CD: GitHub Actions + Fastlane

- **Why GitHub Actions:** Native integration with the repository. Matrix builds for Rust (fmt, clippy, test, build) and Flutter (analyze, test, build). Wrangler deployment on merge.
- **Why Fastlane:** Industry standard for iOS/Android app store deployments. Match for iOS code signing, automated TestFlight and Play Console uploads.

## Consequences

### Positive

- **Unified Cloudflare ecosystem** eliminates cross-service latency and simplifies infrastructure management. One dashboard, one billing account, one deployment tool.
- **Rust on Workers** provides memory safety and performance without a garbage collector, keeping cold start times low and execution fast.
- **Flutter + Riverpod** gives a single mobile codebase with strong typing and testable architecture from day one.
- **Scale-to-zero pricing** means infrastructure cost is proportional to usage during early development.

### Negative

- **Rust on WASM** has a smaller ecosystem than JavaScript Workers. Some npm packages and Workers features may not have Rust equivalents yet.
- **D1 is still maturing.** Write throughput and transaction semantics are more limited than traditional databases. May need to migrate if the app outgrows D1.
- **Cloudflare lock-in.** Deep integration with D1, R2, and Queues makes migration to another cloud provider non-trivial. Mitigated by keeping domain logic separate from infrastructure bindings.
- **Flutter team expertise.** The team must maintain proficiency in both Rust and Dart, two distinct language ecosystems.

### Risks

- If `workers-rs` lags behind the JavaScript Workers API, we may need to write JavaScript shims for newer Cloudflare features.
- D1 row/size limits could become a constraint for recipes with many ingredients or long step lists.
- Clerk's Flutter SDK is newer than their web SDK; breaking changes are possible.

## References

- [Cloudflare Workers Rust docs](https://developers.cloudflare.com/workers/languages/rust/)
- [workers-rs GitHub](https://github.com/cloudflare/workers-rs)
- [Flutter documentation](https://docs.flutter.dev/)
- [Riverpod documentation](https://riverpod.dev/)
- [Clerk documentation](https://clerk.com/docs)
