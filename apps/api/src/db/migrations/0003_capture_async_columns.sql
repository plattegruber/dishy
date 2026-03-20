-- Migration 0003: Add columns for async capture pipeline
-- Supports social link and screenshot capture via Cloudflare Queues.
-- error_message: stores failure details when pipeline_state = 'failed'
-- recipe_id: links the capture to its produced recipe after resolution

ALTER TABLE capture_inputs ADD COLUMN error_message TEXT;
ALTER TABLE capture_inputs ADD COLUMN recipe_id TEXT REFERENCES recipes(id);

CREATE INDEX IF NOT EXISTS idx_capture_inputs_recipe_id ON capture_inputs(recipe_id);
