# ADR 008: AI-Powered Extraction from Social Links and Screenshots

## Status

Accepted

## Date

2026-03-20

## Context

Dishy's capture pipeline initially only supported manual text input. Users paste
or type recipe text, which is synchronously processed through the Claude
extraction pipeline. To reach "best-in-class capture" (SPEC goal), we need to
support the most common way users discover recipes: social media links and
screenshots.

Social link extraction (Instagram, TikTok, YouTube, blogs) and screenshot OCR
are inherently slower and less predictable than manual text input. They involve
fetching external pages, parsing HTML, or running vision models. These
operations can take 10-30 seconds, which exceeds the Cloudflare Workers CPU
time limit for synchronous requests.

## Decision

### Async pipeline via Cloudflare Queues

We introduce a Cloudflare Queue (`dishy-capture-queue`) to process social link
and screenshot captures asynchronously. The HTTP handler:

1. Validates the input (URL format, base64 image data).
2. Saves the capture input to D1 with `pipeline_state: received`.
3. Enqueues a `CaptureJob` message on the queue.
4. Returns **202 Accepted** with the capture ID.

The queue consumer:

1. Transitions the state to `processing`.
2. Runs the appropriate extraction (social fetch or Claude Vision OCR).
3. Feeds extracted text into the existing Claude structuring pipeline.
4. Assembles the recipe, saves to D1.
5. Transitions the state to `resolved` (or `failed`).

Manual text capture remains **synchronous** (200 OK with recipe) since it
completes within the Workers CPU budget.

### Social link extraction

A new `services/social.rs` module:

- Detects the platform from the URL (Instagram, TikTok, YouTube, website).
- Fetches the page HTML via the Worker Fetch API.
- Strips HTML tags to extract readable text.
- Feeds the text into `extract_recipe_from_text` (existing Claude pipeline).

### Screenshot/image extraction via Claude Vision

A new `services/ocr.rs` module:

- Accepts raw image bytes (JPEG, PNG, GIF, WebP).
- Detects the image format from magic bytes.
- Sends the image as a base64-encoded content block to the Anthropic Messages
  API using Claude's vision capability.
- Returns the extracted text for further structuring.

### Capture status polling

A new endpoint `GET /captures/:id` returns the current pipeline state:

```json
{
  "capture_id": "...",
  "pipeline_state": "processing",
  "recipe_id": null,
  "error_message": null
}
```

The Flutter app polls this endpoint every 2 seconds until the capture reaches a
terminal state (`resolved` or `failed`).

### State machine (SPEC section 10)

The pipeline state transitions follow the spec:

```
Received -> Processing -> Extracted -> Resolved
                                     -> Failed
```

State is tracked in the `capture_inputs.pipeline_state` column in D1.

## Consequences

### Positive

- Users can capture recipes from any social media URL or screenshot.
- Async processing avoids CPU time limits on Workers.
- Failed captures are recorded in D1 for debugging and retry.
- Manual text capture is unaffected (still synchronous).
- The queue DLQ catches truly unprocessable messages.

### Negative

- Polling introduces latency for the user (2-second intervals).
- Queue consumer errors require monitoring (Axiom logs).
- Social link extraction depends on page structure and may fail for
  heavily-JavaScript-rendered pages.
- Image size is limited to 20MB (Anthropic API limit).

### Risks

- Social platforms may block or rate-limit the fetch requests. Mitigated by
  respectful User-Agent header and retry via queue.
- Claude Vision API costs are higher per-request than text extraction.
  Mitigated by validating image format and size before sending.

## Alternatives Considered

1. **WebSocket for real-time updates**: More complex infrastructure; polling is
   simpler and sufficient for 10-30 second operations.
2. **Durable Objects for state**: More expensive and complex; D1 + Queue is
   the simpler Cloudflare-native approach.
3. **Client-side OCR**: Would require large model downloads on mobile; server-
   side Claude Vision provides better accuracy.
