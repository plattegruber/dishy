# ADR-005: Manual Capture Pipeline

## Status

Accepted

## Context

The Dishy app needs to convert unstructured recipe content into structured, persisted recipes. The SPEC defines a multi-stage pipeline: Capture -> Extract -> Structure -> Normalize -> Enrich -> Present. We need to implement the first working vertical slice of this pipeline.

## Decision

### Manual text capture as the first slice

We chose manual text input as the first capture modality because:

1. **Simplest input path** -- no OCR, ASR, or web scraping needed.
2. **Exercises the full pipeline** -- every stage from capture to display is touched.
3. **Validates the architecture** -- proves the domain model, D1 schema, pipeline contracts, and frontend can work end-to-end.

### Claude API for extraction

We use Anthropic's Claude Messages API with `tool_use` (structured output) to extract recipe data from raw text because:

1. **Deterministic output** -- `tool_use` with a JSON schema constrains the model to return exactly the shape we need (`StructuredRecipeCandidate`).
2. **High quality extraction** -- Claude excels at parsing unstructured natural language into structured data.
3. **No custom NLP needed** -- avoids building and maintaining regex-based or rule-based parsers.

The extraction tool schema defines:
- `title` (optional string)
- `ingredients` (array of strings)
- `steps` (array of strings)
- `servings` (optional integer)
- `time_minutes` (optional integer)
- `tags` (array of strings)
- `confidence` (number 0.0-1.0)

### Simplified pipeline for Phase 4

For this first slice, we implement:
- `extract_recipe()` -- creates an ExtractionArtifact from Manual input
- `extract_recipe_from_text()` -- calls Claude API for structured extraction
- `structure_recipe()` -- passes through already-structured data
- `parse_ingredients()` -- stub (returns unparsed lines)
- `resolve_ingredients()` -- stub (returns Unmatched resolutions)
- `compute_nutrition()` -- stub (returns Unavailable)
- `generate_cover()` -- stub (returns placeholder GeneratedCover)
- `assemble_recipe()` -- combines all outputs into a ResolvedRecipe

The stubs will be replaced with real implementations in later phases.

### D1 persistence with user_id

We added a `user_id` column to the `recipes` table (migration 0002) so that:
- `GET /recipes` can filter by the authenticated user
- `GET /recipes/:id` enforces ownership (returns 404 for other users' recipes)
- The capture pipeline associates recipes with their creator

### Frontend architecture

The Flutter frontend follows the existing patterns:
- **Riverpod providers** for state management (capture flow, recipe list, recipe detail)
- **GoRouter** for navigation with auth guard
- **Freezed models** for typed domain objects
- **Dio with interceptors** for API calls with correlation IDs

## Consequences

### Positive
- The app works end-to-end for the simplest path
- The architecture is validated before adding complexity
- All pipeline stages have correct signatures for future implementation
- The Claude API integration is proven and can be reused for other modalities

### Negative
- Nutrition, ingredient resolution, and cover generation are stubs
- Only manual text input is supported (other modalities return NotImplemented)
- Claude API calls add latency (typically 2-5 seconds)
- ANTHROPIC_API_KEY must be configured as a Cloudflare Worker secret

### Risks
- Claude API costs scale with usage (mitigated by rate limiting in future phases)
- Extraction quality varies with input text quality (mitigated by confidence scoring)
