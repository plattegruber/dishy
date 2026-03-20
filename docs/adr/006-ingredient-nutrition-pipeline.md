# ADR-006: Ingredient Parsing, USDA Resolution, and Nutrition Computation

## Status

Accepted

## Date

2026-03-20

## Context

The Dishy capture pipeline (SPEC sections 5.4 and 5.5) requires:

1. **Ingredient parsing**: Convert free-text ingredient lines (e.g., "2 cups all-purpose flour, sifted") into structured data (quantity, unit, name, preparation).
2. **Ingredient resolution**: Match parsed ingredients against a food database to get nutritional data.
3. **Nutrition computation**: Aggregate nutritional facts across all ingredients into per-recipe and per-serving totals.

Prior to this change, the pipeline had stub implementations for all three stages that returned placeholder data.

## Decision

### Ingredient Parsing: Claude API with tool_use

We use the Anthropic Claude API (tool_use) for ingredient parsing rather than regex-based or rule-based approaches.

**Rationale:**
- Ingredient text is highly variable ("a pinch of salt", "2-3 cloves garlic, minced", "1 (14 oz) can diced tomatoes").
- Claude's natural language understanding handles edge cases far better than regex.
- tool_use ensures structured, typed output matching our domain model.
- We already have the Claude API integration from the extraction service.

**Fallback:** A heuristic parser is included as a fallback when the Claude API is unavailable (e.g., API key not configured, rate limit hit). This ensures the pipeline always produces some parsed output.

### Ingredient Resolution: USDA FoodData Central

We use the USDA FoodData Central (FDC) API as the primary food database.

**Rationale:**
- Free API with no auth complexity (just a data.gov API key).
- Comprehensive food database (SR Legacy, Foundation, Branded).
- 1,000 requests/hour rate limit is sufficient for our use case.
- Public domain data (CC0 license).

**Resolution strategy:**
- Search by ingredient name using `/foods/search`.
- Filter to SR Legacy and Foundation data types for reliable standard foods.
- Classify results as Matched (>0.8 confidence), FuzzyMatched (0.4-0.8), or Unmatched (<0.4).
- Confidence combines string similarity with FDC search relevance score.

### Nutrition Computation: Aggregation with Graceful Degradation

Nutrition is computed by fetching per-100g nutrient data from FDC for each matched ingredient and aggregating.

**Key design decisions:**
- Nutrition never fails the pipeline. If computation fails, status is `Unavailable`.
- Partial matches produce `Estimated` status, not an error.
- Per-serving values are computed when the recipe has a known serving count.
- Four primary macros: calories (kcal), protein (g), carbs (g), fat (g).
- Nutrient IDs: Energy=208, Protein=203, Fat=204, Carbs=205.

### API Key Management

- `ANTHROPIC_API_KEY` (existing) for ingredient parsing.
- `FDC_API_KEY` (new) for USDA FDC lookups. Set via `npx wrangler secret put FDC_API_KEY`.
- Both keys degrade gracefully when not configured.

## Consequences

### Positive
- Accurate ingredient parsing via Claude NLU.
- Real nutrition data from USDA, the gold standard for US food data.
- Pipeline never fails hard -- degrades to Unmatched/Unavailable.
- Per-serving toggle gives users useful dietary information.
- Frontend shows resolution confidence so users know data quality.

### Negative
- Two external API dependencies (Anthropic + USDA) in the critical path.
- USDA rate limit (1,000/hr) could be hit with heavy usage.
- Nutrition accuracy limited by quantity-to-gram conversion (currently uses raw quantity as a scale factor).
- Claude API cost per capture increases slightly with ingredient parsing call.

### Mitigations
- Heuristic fallback parser for when Claude is unavailable.
- Graceful degradation at every stage.
- Future: Cache FDC results in D1 to reduce API calls.
- Future: Implement proper unit-to-gram conversion tables.

## Alternatives Considered

1. **Regex-based ingredient parser**: Rejected due to high variability of ingredient text.
2. **Edamam API for nutrition**: Considered as fallback (400 req/month free tier). May add in future.
3. **Client-side nutrition computation**: Rejected; keeping nutrition computation server-side keeps the API key secure and allows reprocessing.
