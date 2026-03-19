# SPEC: Recipe Capture & Cooking App

## 1. Problem Statement

Consumers discover recipes primarily through short-form content (Instagram Reels, TikTok, etc.), but:

- Recipes are unstructured and inconsistent.
- Saving is manual and lossy.
- Existing apps are cluttered or unattractive.
- Transition from discovery → cooking is high friction.

This system solves:

**Convert messy, ephemeral food content into structured, beautiful, and usable recipes with minimal user effort.**

## 2. Goals

### Primary Goals

- **Best-in-class capture:** Any input → structured recipe in < 60 seconds.
- **Visual coherence:** All saved recipes look curated and consistent.
- **Fast path to cooking:** Minimal friction between saving and usage.
- **Trustworthy output:** Users can rely on extracted recipes.

### Secondary Goals

- Provide basic nutrition information.
- Enable grocery list generation.
- Support reprocessing as extraction improves.

## 3. Non-Goals (V1)

- Social network features
- Meal planning systems
- Pantry tracking
- Power-user workflows (folders, deep editing)
- Desktop-first UX

## 4. System Overview

The system is a deterministic, reprocessable pipeline:

```
Capture → Extract → Structure → Normalize → Enrich → Present
```

Each stage:

- Is idempotent.
- Produces immutable outputs.
- Can be re-run independently.

## 5. Major Components

### 5.1 Capture Service

- **Responsibility:** Accept user input from multiple modalities.
- **Inputs:** Social links, Images (screenshots, scans), Speech, Text.
- **Output:** `CaptureInput`

### 5.2 Extraction Service

- **Responsibility:** Convert raw input into candidate structured data.
- **Includes:** OCR (images), ASR (speech), LLM extraction.
- **Output:** `ExtractionArtifact`

### 5.3 Structuring Service

- **Responsibility:** Convert raw extraction into a recipe candidate.
- **Tasks:** Identify ingredients vs. steps, infer metadata (time, servings), remove noise.
- **Output:** `StructuredRecipeCandidate`

### 5.4 Ingredient Pipeline

- **Parsing:** Convert text → structured ingredient.
- **Resolution:** Match ingredient → known food entity.
- **Output:** `[ResolvedIngredient]`

### 5.5 Nutrition Service

- **Responsibility:** Compute nutrition from resolved ingredients.
- **Uses:** External provider(s).
- **Output:** `NutritionComputation`

### 5.6 Cover Generation Service

- **Responsibility:** Generate consistent visual representation.
- **Tasks:** Image ranking, cropping, enhancement, fallback generation.
- **Output:** `CoverOutput`

### 5.7 Recipe Assembly Service

- **Responsibility:** Combine all outputs into canonical recipe.
- **Output:** `ResolvedRecipe`

### 5.8 User Layer

- **Responsibility:** Overlay user-specific state.
- **Output:** `UserRecipeView`

## 6. Abstraction Layers

- **Input Layer:** `CaptureInput`
- **Extraction Layer:** `ExtractionArtifact`
- **Domain Layer:** `StructuredRecipeCandidate` → `ResolvedRecipe`
- **Enrichment Layer:** Ingredient resolution, Nutrition, Cover
- **User Layer:** `UserRecipeView`

## 7. External Dependencies

### Required

- Nutrition provider (USDA initially)

### Optional

- Edamam / FatSecret
- LLM provider
- Image processing

## 8. Domain Model

### 8.1 Inputs & Artifacts

```typescript
type CaptureInput =
  | SocialLink(url)
  | Screenshot(image)
  | Scan(image)
  | Speech(transcript)
  | Manual(text)

interface ExtractionArtifact {
  id: CaptureId
  version: Int
  rawText: Text?
  ocrText: Text?
  transcript: Text?
  ingredients: [Text]
  steps: [Text]
  images: [Image]
  source: Source
  confidence: Float
}

interface StructuredRecipeCandidate {
  title: Text?
  ingredientLines: [Text]
  steps: [Text]
  servings: Int?
  time: Duration?
  tags: [Text]
  confidence: Float
}
```

### 8.2 Ingredients

```typescript
interface IngredientLine {
  rawText: Text
  parsed: ParseResult<ParsedIngredient>
}

interface ParsedIngredient {
  quantity: Quantity?
  unit: Unit?
  name: Text
  preparation: Text?
}

interface ResolvedIngredient {
  parsed: ParsedIngredient
  resolution: IngredientResolution
}

type IngredientResolution =
  | Matched(foodId, confidence)
  | FuzzyMatched(candidates, confidence)
  | Unmatched(text)
```

### 8.3 Nutrition & Presentation

```typescript
interface NutritionFacts {
  calories: Float
  protein: Float
  carbs: Float
  fat: Float
}

interface NutritionComputation {
  perRecipe: NutritionFacts
  perServing: NutritionFacts?
  status: NutritionStatus
}

type CoverOutput =
  | SourceImage(assetId)
  | EnhancedImage(assetId)
  | GeneratedCover(assetId)

interface Source {
  platform: Platform
  url: Url?
  creatorHandle: Text?
  creatorId: Text?
}
```

### 8.4 Final Outputs

```typescript
interface ResolvedRecipe {
  id: RecipeId
  title: Text
  ingredients: [ResolvedIngredient]
  steps: [Step]
  servings: Int?
  time: Duration?
  source: Source
  nutrition: NutritionComputation
  cover: CoverOutput
  tags: [Text]
}

interface UserRecipeView {
  recipeId: RecipeId
  userId: UserId
  saved: Bool
  favorite: Bool
  notes: Text?
  patches: [RecipePatch]
}
```

## 9. Pipeline Contracts

```typescript
extractRecipe(CaptureInput) -> Result<ExtractionArtifact>
structureRecipe(ExtractionArtifact) -> Result<StructuredRecipeCandidate>
parseIngredients(StructuredRecipeCandidate) -> [IngredientLine]
resolveIngredients([IngredientLine]) -> [ResolvedIngredient]
computeNutrition([ResolvedIngredient]) -> NutritionComputation
generateCover(CoverInput) -> CoverOutput
assembleRecipe(...) -> ResolvedRecipe
```

## 10. State Machines

**Capture Pipeline:**

```
Received → Processing → Extracted → NeedsReview → Resolved → Failed
```

**Nutrition:**

```
Pending → Calculated → Estimated → Unavailable
```

## 11. Persistence Model

**Persist:**

- `CaptureInput`
- `ExtractionArtifact` (versioned)
- `ResolvedRecipe`
- `UserRecipeView`

**Requirements:**

- Reprocessing support
- Versioning
- Auditability

## 12. Reprocessing Strategy

**Actions:**

- Re-run extraction with new models
- Recompute nutrition
- Regenerate covers

**Rules:**

- Never overwrite original data
- Always version outputs
- Allow background upgrades

## 13. Failure Handling

Failures must be explicit, preserve partial progress, and allow retry.

**Examples:**

- OCR failure → Trigger fallback
- Ingredient unmatched → Mark for review
- Nutrition unavailable → Degrade gracefully

## 14. Observability

**Track:**

- Extraction success rate
- Ingredient match rate
- Nutrition coverage
- Cover fallback rate

## 15. UX Surfaces

- **Home:** Grid layout, auto-grouped sections, primary capture entry point.
- **Recipe View:** Clean layout, hands-free cooking mode, nutrition display.
- **Grocery:** Single consolidated list, grouped items (e.g., by aisle/category).

## 16. Security & Attribution

- Preserve creator attribution.
- Keep original source links.
- Respect platform policies (scraping/API rules).

## 17. Definition of Done

- Save recipe in < 60 seconds.
- Output is usable without manual edits.
- Recipe grid is visually consistent.
- Nutrition is present for the majority of recipes.
- System successfully supports reprocessing of old data.

## 18. Engineering Constraints

- No mutation across pipeline stages.
- No collapsing domain layers.
- Explicit transformations only.
- Preserve raw data always.

---

**Final Note:**
This system is a long-lived data pipeline that improves over time, not a static app.
