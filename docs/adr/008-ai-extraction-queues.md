# ADR-008: Social Link and Screenshot Capture with Cloudflare Queues

## Status

Accepted

## Date

2026-03-20

## Context

Dishy's capture pipeline previously only supported manual text input, which
runs synchronously -- the user pastes text, Claude extracts the recipe, and
the response is returned in a single request/response cycle.

To support the remaining SPEC capture modalities (social links and
screenshots), we need:

1. **Social link fetching** -- downloading the HTML from a URL, stripping
   tags, and feeding the text to Claude.
2. **Screenshot OCR** -- sending image bytes to Claude Vision for text
   extraction and recipe structuring.

Both of these are significantly slower than manual text extraction (network
fetches, larger payloads, vision model latency) and would cause HTTP
timeouts if run synchronously in a single Worker request.

## Decision

We use **Cloudflare Queues** to decouple the capture submission (fast) from
the extraction processing (slow):

1. **`POST /recipes/capture`** now supports three `input_type` values:
   - `"manual"` -- synchronous, same as before (returns 201 with recipe)
   - `"social_link"` -- async, returns 202 with `capture_id`
   - `"screenshot"` -- async, returns 202 with `capture_id`

2. For async captures, the endpoint:
   - Saves the `CaptureInput` to D1 with `pipeline_state = "received"`
   - Enqueues a `CaptureQueueMessage` on the `CAPTURE_QUEUE`
   - Returns 202 Accepted immediately

3. The **queue consumer** (`#[event(queue)]`) processes messages:
   - Reads the capture input from D1
   - Runs the appropriate extraction (social fetch or OCR)
   - Assembles the full recipe (ingredients, nutrition, cover)
   - Saves the recipe and updates the capture with `recipe_id`

4. **`GET /captures/:id`** lets the client poll for completion:
   - Returns `pipeline_state`, `recipe_id`, and `error_message`
   - The mobile app polls every 3 seconds until terminal state

### Architecture

```
Client                    Worker (fetch)           Queue Consumer
  |                           |                         |
  |-- POST /recipes/capture ->|                         |
  |                           |-- save to D1            |
  |                           |-- enqueue msg --------->|
  |<-- 202 {capture_id} ------|                         |
  |                           |                         |-- read from D1
  |                           |                         |-- fetch/OCR
  |                           |                         |-- extract recipe
  |                           |                         |-- save recipe
  |                           |                         |-- update capture
  |-- GET /captures/:id ----->|                         |
  |<-- {status, recipe_id} ---|                         |
```

### New Services

- **`services/social.rs`** -- fetches page HTML, strips tags, detects
  platform from URL hostname
- **`services/ocr.rs`** -- sends image bytes to Claude Vision API with
  tool_use for structured extraction
- **`pipeline/queue.rs`** -- queue message types and the `process_capture`
  function that orchestrates the full pipeline

### D1 Schema Changes

Migration `0003_capture_async_columns.sql` adds:
- `error_message TEXT` -- stores failure details for failed captures
- `recipe_id TEXT` -- links completed captures to their produced recipe

### Mobile Changes

- **Tabbed capture screen** with Text, Link, and Photo tabs
- **`image_picker`** dependency for camera/gallery image selection
- **Async polling** in the capture provider (3-second interval)
- Updated `ApiClient` and `RecipeRepository` with new endpoints

## Consequences

### Positive

- Social links and screenshots can take 10-30 seconds to process without
  causing HTTP timeouts
- The user gets immediate feedback (202) and a polling mechanism
- Failed captures are recorded with error messages for debugging
- Queue retries (max 3) with dead letter queue handle transient failures
- Manual text capture is unchanged -- no regression

### Negative

- Added complexity: queue consumer, D1 state management, client polling
- Polling is not as efficient as WebSockets or SSE, but is simpler to
  implement on Cloudflare Workers
- Screenshot upload adds R2 storage cost for the intermediate image

### Risks

- Cloudflare Queue message ordering is not guaranteed (acceptable since
  each capture is independent)
- If the queue consumer crashes after updating state to "processing" but
  before completing, the capture stays stuck -- mitigated by the DLQ and
  max_retries configuration
