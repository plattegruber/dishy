-- Migration 0003: Add pipeline tracking columns for async capture processing
-- Supports social link and screenshot captures via Cloudflare Queues.
--
-- Adds error_message and recipe_id to capture_inputs so the queue consumer
-- can record the final result or failure reason.

ALTER TABLE capture_inputs ADD COLUMN error_message TEXT;
ALTER TABLE capture_inputs ADD COLUMN recipe_id TEXT;

CREATE INDEX IF NOT EXISTS idx_capture_inputs_recipe_id ON capture_inputs(recipe_id);
