-- Migration 0001: Initial schema
-- Creates all tables for the Dishy domain model.
-- Applied to Cloudflare D1 via: npx wrangler d1 migrations apply DB

-- capture_inputs: Raw user input that initiated the capture pipeline
CREATE TABLE IF NOT EXISTS capture_inputs (
    id              TEXT PRIMARY KEY,
    user_id         TEXT NOT NULL,
    input_type      TEXT NOT NULL,
    input_data      TEXT NOT NULL,
    pipeline_state  TEXT NOT NULL DEFAULT 'received',
    created_at      TEXT NOT NULL,
    updated_at      TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_capture_inputs_user_id ON capture_inputs(user_id);
CREATE INDEX IF NOT EXISTS idx_capture_inputs_pipeline_state ON capture_inputs(pipeline_state);

-- extraction_artifacts: Versioned extraction results (never overwritten)
CREATE TABLE IF NOT EXISTS extraction_artifacts (
    id              TEXT NOT NULL,
    capture_id      TEXT NOT NULL,
    version         INTEGER NOT NULL,
    raw_text        TEXT,
    ocr_text        TEXT,
    transcript      TEXT,
    ingredients_json TEXT NOT NULL DEFAULT '[]',
    steps_json      TEXT NOT NULL DEFAULT '[]',
    images_json     TEXT NOT NULL DEFAULT '[]',
    source_json     TEXT NOT NULL,
    confidence      REAL NOT NULL DEFAULT 0.0,
    created_at      TEXT NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (capture_id) REFERENCES capture_inputs(id)
);

CREATE INDEX IF NOT EXISTS idx_extraction_artifacts_capture_id ON extraction_artifacts(capture_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_extraction_artifacts_capture_version ON extraction_artifacts(capture_id, version);

-- recipes: The resolved canonical recipe
CREATE TABLE IF NOT EXISTS recipes (
    id              TEXT PRIMARY KEY,
    capture_id      TEXT,
    title           TEXT NOT NULL,
    servings        INTEGER,
    time_minutes    INTEGER,
    source_json     TEXT NOT NULL,
    nutrition_json  TEXT NOT NULL,
    cover_json      TEXT NOT NULL,
    tags_json       TEXT NOT NULL DEFAULT '[]',
    created_at      TEXT NOT NULL,
    updated_at      TEXT NOT NULL,
    FOREIGN KEY (capture_id) REFERENCES capture_inputs(id)
);

CREATE INDEX IF NOT EXISTS idx_recipes_capture_id ON recipes(capture_id);

-- recipe_ingredients: Resolved ingredients for a recipe
CREATE TABLE IF NOT EXISTS recipe_ingredients (
    id              TEXT PRIMARY KEY,
    recipe_id       TEXT NOT NULL,
    position        INTEGER NOT NULL,
    raw_text        TEXT NOT NULL,
    parsed_json     TEXT,
    resolution_json TEXT NOT NULL,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id)
);

CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_recipe_id ON recipe_ingredients(recipe_id);

-- recipe_steps: Ordered instruction steps for a recipe
CREATE TABLE IF NOT EXISTS recipe_steps (
    id              TEXT PRIMARY KEY,
    recipe_id       TEXT NOT NULL,
    step_number     INTEGER NOT NULL,
    instruction     TEXT NOT NULL,
    time_minutes    INTEGER,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id)
);

CREATE INDEX IF NOT EXISTS idx_recipe_steps_recipe_id ON recipe_steps(recipe_id);

-- user_recipe_views: Per-user overlay on a recipe
CREATE TABLE IF NOT EXISTS user_recipe_views (
    recipe_id       TEXT NOT NULL,
    user_id         TEXT NOT NULL,
    saved           INTEGER NOT NULL DEFAULT 0,
    favorite        INTEGER NOT NULL DEFAULT 0,
    notes           TEXT,
    patches_json    TEXT NOT NULL DEFAULT '[]',
    created_at      TEXT NOT NULL,
    updated_at      TEXT NOT NULL,
    PRIMARY KEY (recipe_id, user_id),
    FOREIGN KEY (recipe_id) REFERENCES recipes(id)
);

CREATE INDEX IF NOT EXISTS idx_user_recipe_views_user_id ON user_recipe_views(user_id);
