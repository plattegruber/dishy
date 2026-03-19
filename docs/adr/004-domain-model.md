# ADR-004: Domain Model, D1 Schema, and Persistence Strategy

## Status

Accepted

## Context

Dishy needs a comprehensive domain model that spans the entire capture pipeline (SPEC §8) and supports persistence in Cloudflare D1 (SPEC §11). The model must be represented in both Rust (backend) and Dart (frontend) with full type safety, serialization roundtrip guarantees, and no data loss during reprocessing.

Key requirements from the spec:
- Every pipeline stage produces immutable outputs (§4, §18).
- Extraction artifacts are versioned — raw data is never overwritten (§11, §12).
- The model supports reprocessing, auditing, and background upgrades (§12).
- User state (saves, favorites, patches) is overlaid on canonical recipes without mutating them (§8.4).

## Decision

### Type System

**Rust (Backend):**
- Branded ID types as newtype wrappers: `pub struct RecipeId(String)`. Prevents mixing IDs from different entities.
- Sum types (enums) use serde `tag` for JSON discrimination: `#[serde(tag = "type", rename_all = "snake_case")]`.
- All types derive `Debug, Clone, Serialize, Deserialize`.
- `Option<T>` for nullable fields (serializes as JSON `null`).
- No `.unwrap()` anywhere in production code.

**Dart (Frontend):**
- ID types as `typedef` aliases (e.g., `typedef RecipeId = String`). Dart doesn't support branded newtypes, so typedefs provide documentation value.
- Data classes via `@freezed` with `@JsonSerializable` for codegen.
- Sealed classes for union types (e.g., `CaptureInput`, `IngredientResolution`, `CoverOutput`).
- Enums for simple discriminated values (e.g., `Platform`, `NutritionStatus`).
- No `dynamic` types.

### State Machines

Pipeline state machines are modeled as enums with transition methods that return `Result` (Rust) or use extension methods with `Set<State>` (Dart). Invalid transitions produce errors rather than silently succeeding.

- **CapturePipelineState:** Received -> Processing -> Extracted -> NeedsReview -> Resolved | Failed
- **NutritionState:** Pending -> Calculated | Estimated | Unavailable

### D1 Schema Design

The D1 schema uses six tables:

| Table | Purpose | Key Design Choices |
|-------|---------|-------------------|
| `capture_inputs` | Raw user input | JSON column for variant payload; `pipeline_state` tracks progress |
| `extraction_artifacts` | Versioned extraction results | Composite unique index on `(capture_id, version)` for reprocessing |
| `recipes` | Canonical resolved recipes | Complex nested objects stored as JSON columns (`source_json`, `nutrition_json`, `cover_json`, `tags_json`) |
| `recipe_ingredients` | Resolved ingredients | Separate table for queryability; `position` column for ordering |
| `recipe_steps` | Ordered instructions | Separate table; `step_number` for ordering |
| `user_recipe_views` | Per-user recipe overlay | Composite primary key `(recipe_id, user_id)`; upsert semantics |

**JSON columns vs. normalized tables:** Complex, variable-structure data (Source, NutritionComputation, CoverOutput, tags) is stored as JSON text columns. This trades query flexibility for simplicity — these fields are always read/written as a unit and never queried independently. Ingredients and steps are normalized into separate tables because they need to be queried and displayed independently.

**Timestamps:** ISO-8601 text strings (SQLite has no native datetime type). All tables include `created_at`; mutable tables also include `updated_at`.

**Foreign keys:** Enforced via `FOREIGN KEY` constraints. Indexes on all foreign key columns and common query predicates.

### Pipeline Contracts

Pipeline stage functions are defined with correct types but stub implementations. Each function:
- Takes typed domain inputs and produces typed domain outputs.
- Returns `Result<T, PipelineError>` for fallible stages.
- Is `async` to support I/O (API calls, database queries).
- Will be implemented in later phases with real extraction, structuring, and nutrition logic.

## Consequences

- **Type safety:** ID mixups are caught at compile time (Rust) or flagged by documentation (Dart). Serialization roundtrips are tested for every type.
- **Reprocessing support:** Extraction artifacts are versioned. Original data is never overwritten. New pipeline runs create new artifact versions.
- **Auditability:** All tables have timestamps. Pipeline state is tracked per capture.
- **Migration path:** The initial migration creates the full schema. Future schema changes will be added as numbered migrations (0002, 0003, etc.).
- **Generated code:** Dart freezed/json_serializable files are committed to the repo. Regenerate with `dart run build_runner build --delete-conflicting-outputs`.
