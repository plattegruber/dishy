# ADR-007: Cover Image Generation with R2 Storage

## Status

Accepted

## Date

2026-03-20

## Context

The Dishy capture pipeline (SPEC section 5.6) requires a Cover Generation Service that produces a consistent visual representation for every recipe. Prior to this change, the `generateCover()` pipeline stage was a stub returning a hardcoded placeholder asset ID.

The system needs to:

1. Accept user-uploaded images for recipe covers.
2. Store images durably with low latency for retrieval.
3. Always produce a cover — never leave a recipe without one.
4. Generate visually consistent fallback covers when no image is available.

## Decision

### Storage: Cloudflare R2

We use Cloudflare R2 for image storage via the `IMAGES` bucket binding.

**Rationale:**
- Zero egress fees — critical for an image-heavy application.
- S3-compatible API, well-supported by `workers-rs`.
- Co-located with our Workers compute, minimizing latency.
- Simple binding model via `wrangler.toml`.

**R2 types:** In `worker` crate 0.7, R2 types are at `worker::HttpMetadata` and `worker::Data::Bytes` (the `worker::r2::` module is private and not directly accessible).

### Image Validation

- **Supported types:** JPEG, PNG, WebP.
- **Maximum size:** 10 MB.
- Validation occurs before upload to avoid storing invalid data.

### Cover Generation Strategy

The cover service follows a three-tier fallback:

1. **Source image available:** Upload to R2, return `CoverOutput::SourceImage`.
2. **No image, R2 available:** Generate a deterministic SVG placeholder, upload to R2, return `CoverOutput::GeneratedCover`.
3. **No image, R2 unavailable:** Return a deterministic placeholder asset ID (not stored) so the client can render a local color placeholder.

**SVG placeholders** use:
- A DJB2 hash of the recipe title to deterministically select a background color from a 10-color warm palette.
- The first letter of the title as a centered initial.
- The truncated title as subtitle text.

The same hash algorithm is implemented in both Rust (API) and Dart (mobile) so the client can display matching placeholder colors before the SVG loads.

### API Routes

- `GET /images/:asset_id` — Unauthenticated image serving with `Cache-Control: public, max-age=31536000, immutable` (1-year cache for immutable assets).
- `POST /recipes/:id/cover` — Authenticated image upload. Validates content type and size, uploads to R2, updates the recipe's cover in D1.

### Frontend Integration

- **`RecipeCard` widget** — New shared widget used in the recipe grid. Shows the cover image or a colored placeholder with the recipe's initial.
- **Hero cover** — Recipe detail screen shows a 200px hero cover image at the top.
- **`cover_image.dart` utilities** — URL construction, placeholder color generation (matching the API's DJB2 hash), and initial extraction.

### Pipeline Integration

The `generate_cover()` contract function now accepts an optional R2 bucket reference. When available, it delegates to the real cover service. When absent (e.g., in unit tests), it falls back to `generate_cover_stub()` which returns a deterministic placeholder.

## Consequences

### Positive

- Every recipe always has a cover — the pipeline never fails on this stage.
- Deterministic placeholders look consistent and attractive.
- Client-side color matching provides instant visual feedback.
- Immutable asset IDs enable aggressive caching (1-year max-age).
- Image serving is unauthenticated, simplifying `<img>` tag usage.
- R2 zero-egress model controls costs.

### Negative

- Generated SVG placeholders are simple (initial + color) — not as polished as AI-generated images.
- Multipart upload parsing in the Worker is basic (raw bytes with Content-Type header, not full multipart form parsing).
- No image processing (resize, crop, optimize) — uploaded images are stored as-is.

### Mitigations

- Future: Add image processing (resize to standard dimensions, WebP conversion) to reduce storage and bandwidth.
- Future: AI-generated covers from recipe text when no image is available.
- Future: CDN layer (Cloudflare Cache) in front of R2 for even faster delivery.

## Alternatives Considered

1. **Cloudflare Images (managed service):** Rejected — adds cost and complexity; R2 is simpler and sufficient for V1.
2. **External CDN (Cloudinary, imgix):** Rejected — adds external dependency; R2 is co-located and free egress.
3. **Client-side placeholder only (no SVG upload):** Rejected — SVG in R2 means the placeholder is visible in any context (web, email, social sharing) without client-side rendering.
4. **Base64 inline images in the recipe JSON:** Rejected — bloats API responses and D1 storage.
