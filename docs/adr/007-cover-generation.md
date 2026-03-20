# ADR-007: Cover Image Generation and R2 Storage

## Status

Accepted

## Date

2026-03-20

## Context

Every recipe in Dishy needs a visual cover image (SPEC section 5.6). Covers are shown in the recipe grid on the home screen and as a hero image on recipe detail. The system must handle two cases:

1. **Source images available** -- the extraction pipeline found images in the original content. These should be uploaded to object storage and used directly.
2. **No images available** -- manual text capture and other input types may not include images. The system must generate a styled placeholder so recipes never appear without a cover.

We need to decide on the storage backend for images, the cover generation strategy, the image serving approach, and how the mobile app loads and displays covers.

## Decision

### Storage: Cloudflare R2

Images are stored in Cloudflare R2 using the `worker` crate's native R2 bindings (`env.bucket("IMAGES")`). This keeps all infrastructure on the Cloudflare platform and avoids external dependencies.

- **Bucket name:** `dishy-images`
- **Binding name:** `IMAGES`
- **Asset ID format:** `{prefix}_{uuid}.{ext}` (e.g., `cover_550e8400-e29b-41d4-a716-446655440000.jpg`)
- **Supported formats:** JPEG, PNG, WebP
- **Max upload size:** 10 MB

### Cover Generation Strategy

The cover service (`services/cover.rs`) implements a two-tier strategy:

1. **Source image selection:** If the extraction pipeline provides images, the first image is selected as the cover (future: ranking by quality/relevance). It is stored as a `CoverOutput::SourceImage`.

2. **Fallback placeholder:** When no images are available, a minimal SVG is generated with:
   - A solid color background (deterministically selected from a 14-color palette using a hash of the recipe title)
   - The recipe title rendered as white centered text
   - System sans-serif font at 28px
   - 600x400 pixel dimensions

The fallback path **always succeeds** -- a recipe is never left without a cover.

### Image Serving

Images are served via `GET /images/:asset_id`:

- Public endpoint (no authentication required)
- Sets `Content-Type` based on R2 object metadata
- Sets `Cache-Control: public, max-age=31536000, immutable` (1-year immutable cache)
- CDN-friendly headers for edge caching

### Image Upload

Users can upload custom cover images via `POST /recipes/:id/cover`:

- Requires authentication (Clerk JWT)
- Validates ownership (recipe must belong to the authenticated user)
- Accepts raw binary body with Content-Type header
- Validates file type (JPEG, PNG, WebP only) and size (max 10 MB)
- Uploads to R2 and updates the recipe's `cover_json` in D1

### Mobile Display

The Flutter app handles covers through:

- **Image provider** (`image_provider.dart`): Utility functions for URL construction, placeholder detection, and deterministic color generation
- **Recipe card widget** (`recipe_card.dart`): Shows cover images in the grid with loading and error fallbacks
- **Recipe detail hero**: Full-width cover at the top of the detail view
- **Placeholder detection**: Covers with asset IDs starting with `placeholder_` or `generated_` use local placeholder widgets instead of network loading

The mobile placeholder colors use the same hashing algorithm as the backend to maintain visual consistency.

## Consequences

### Positive

- Recipes always have a visual cover (never blank)
- Placeholder colors are deterministic and consistent across backend and frontend
- R2 integration uses native Worker bindings (no HTTP overhead)
- Immutable cache headers enable aggressive CDN caching
- Image validation prevents abuse (size limits, format restrictions)

### Negative

- Generated SVG placeholders are simple (no fancy gradients or illustrations)
- No image processing (cropping, resizing, optimization) in V1
- The first extraction image is selected without quality ranking

### Future Improvements

- Image quality ranking when multiple source images are available
- Server-side image resizing (R2 Image Transformations)
- Enhanced generated covers with gradients, patterns, or AI-generated imagery
- Progressive JPEG/WebP optimization for faster loading
- Thumbnail generation for the grid view

## References

- SPEC section 5.6: Cover Generation Service
- SPEC section 8.3: `CoverOutput` domain type
- Cloudflare R2 documentation: https://developers.cloudflare.com/r2/
