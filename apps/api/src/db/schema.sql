-- Dishy D1 Database Schema
-- Full CREATE TABLE statements for the recipe capture domain model.
-- See SPEC §11 for the persistence model requirements.
--
-- Design principles:
--   - Raw data is never overwritten (versioning on extraction artifacts).
--   - JSON columns store complex/variable structures (ingredients, steps, tags).
--   - Foreign keys enforce referential integrity.
--   - Timestamps use ISO-8601 text (SQLite has no native datetime).

-- ──────────────────────────────────────────────────────────────────
-- capture_inputs: Raw user input that initiated the capture pipeline
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS capture_inputs (
    id              TEXT PRIMARY KEY,           -- CaptureId
    user_id         TEXT NOT NULL,              -- UserId (Clerk user)
    input_type      TEXT NOT NULL,              -- 'social_link' | 'screenshot' | 'scan' | 'speech' | 'manual'
    input_data      TEXT NOT NULL,              -- JSON: full CaptureInput variant payload
    pipeline_state  TEXT NOT NULL DEFAULT 'received', -- CapturePipelineState
    created_at      TEXT NOT NULL,              -- ISO-8601 timestamp
    updated_at      TEXT NOT NULL               -- ISO-8601 timestamp
);

CREATE INDEX IF NOT EXISTS idx_capture_inputs_user_id ON capture_inputs(user_id);
CREATE INDEX IF NOT EXISTS idx_capture_inputs_pipeline_state ON capture_inputs(pipeline_state);

-- ──────────────────────────────────────────────────────────────────
-- extraction_artifacts: Versioned extraction results (never overwritten)
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS extraction_artifacts (
    id              TEXT NOT NULL,              -- ArtifactId
    capture_id      TEXT NOT NULL,              -- FK → capture_inputs.id
    version         INTEGER NOT NULL,           -- Version number (1, 2, 3, ...)
    raw_text        TEXT,                       -- Raw text from input
    ocr_text        TEXT,                       -- OCR-extracted text
    transcript      TEXT,                       -- Speech transcript
    ingredients_json TEXT NOT NULL DEFAULT '[]', -- JSON array of ingredient strings
    steps_json      TEXT NOT NULL DEFAULT '[]', -- JSON array of step strings
    images_json     TEXT NOT NULL DEFAULT '[]', -- JSON array of AssetId strings
    source_json     TEXT NOT NULL,              -- JSON: Source object
    confidence      REAL NOT NULL DEFAULT 0.0,  -- Extraction confidence (0.0–1.0)
    created_at      TEXT NOT NULL,              -- ISO-8601 timestamp
    PRIMARY KEY (id),
    FOREIGN KEY (capture_id) REFERENCES capture_inputs(id)
);

CREATE INDEX IF NOT EXISTS idx_extraction_artifacts_capture_id ON extraction_artifacts(capture_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_extraction_artifacts_capture_version ON extraction_artifacts(capture_id, version);

-- ──────────────────────────────────────────────────────────────────
-- recipes: The resolved canonical recipe
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS recipes (
    id              TEXT PRIMARY KEY,           -- RecipeId
    capture_id      TEXT,                       -- FK → capture_inputs.id (nullable for imported recipes)
    title           TEXT NOT NULL,              -- Recipe title
    servings        INTEGER,                    -- Number of servings
    time_minutes    INTEGER,                    -- Total time in minutes
    source_json     TEXT NOT NULL,              -- JSON: Source object
    nutrition_json  TEXT NOT NULL,              -- JSON: NutritionComputation object
    cover_json      TEXT NOT NULL,              -- JSON: CoverOutput object
    tags_json       TEXT NOT NULL DEFAULT '[]', -- JSON array of tag strings
    created_at      TEXT NOT NULL,              -- ISO-8601 timestamp
    updated_at      TEXT NOT NULL,              -- ISO-8601 timestamp
    FOREIGN KEY (capture_id) REFERENCES capture_inputs(id)
);

CREATE INDEX IF NOT EXISTS idx_recipes_capture_id ON recipes(capture_id);

-- ──────────────────────────────────────────────────────────────────
-- recipe_ingredients: Resolved ingredients for a recipe
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS recipe_ingredients (
    id              TEXT PRIMARY KEY,           -- Unique row ID
    recipe_id       TEXT NOT NULL,              -- FK → recipes.id
    position        INTEGER NOT NULL,           -- Order within the recipe (0-based)
    raw_text        TEXT NOT NULL,              -- Original ingredient text
    parsed_json     TEXT,                       -- JSON: ParsedIngredient (null if parse failed)
    resolution_json TEXT NOT NULL,              -- JSON: IngredientResolution
    FOREIGN KEY (recipe_id) REFERENCES recipes(id)
);

CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_recipe_id ON recipe_ingredients(recipe_id);

-- ──────────────────────────────────────────────────────────────────
-- recipe_steps: Ordered instruction steps for a recipe
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS recipe_steps (
    id              TEXT PRIMARY KEY,           -- Unique row ID
    recipe_id       TEXT NOT NULL,              -- FK → recipes.id
    step_number     INTEGER NOT NULL,           -- 1-based step number
    instruction     TEXT NOT NULL,              -- Step instruction text
    time_minutes    INTEGER,                    -- Duration for this step
    FOREIGN KEY (recipe_id) REFERENCES recipes(id)
);

CREATE INDEX IF NOT EXISTS idx_recipe_steps_recipe_id ON recipe_steps(recipe_id);

-- ──────────────────────────────────────────────────────────────────
-- user_recipe_views: Per-user overlay on a recipe
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_recipe_views (
    recipe_id       TEXT NOT NULL,              -- FK → recipes.id
    user_id         TEXT NOT NULL,              -- UserId (Clerk user)
    saved           INTEGER NOT NULL DEFAULT 0, -- Boolean (0/1)
    favorite        INTEGER NOT NULL DEFAULT 0, -- Boolean (0/1)
    notes           TEXT,                       -- User's personal notes
    patches_json    TEXT NOT NULL DEFAULT '[]', -- JSON array of RecipePatch objects
    created_at      TEXT NOT NULL,              -- ISO-8601 timestamp
    updated_at      TEXT NOT NULL,              -- ISO-8601 timestamp
    PRIMARY KEY (recipe_id, user_id),
    FOREIGN KEY (recipe_id) REFERENCES recipes(id)
);

CREATE INDEX IF NOT EXISTS idx_user_recipe_views_user_id ON user_recipe_views(user_id);
