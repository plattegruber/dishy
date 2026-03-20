-- Migration 0002: Add user_id to recipes table
-- Associates recipes with the user who captured them.
-- Needed for the GET /recipes endpoint to filter by user.

ALTER TABLE recipes ADD COLUMN user_id TEXT;

CREATE INDEX IF NOT EXISTS idx_recipes_user_id ON recipes(user_id);
