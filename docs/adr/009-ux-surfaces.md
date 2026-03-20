# ADR-009: UX Surfaces -- Recipe Grid, Cooking Mode, Grocery List

## Status

Accepted

## Context

SPEC section 15 defines three primary UX surfaces: Home (recipe grid), Recipe View (cooking mode), and Grocery List. The existing app had basic screens but lacked polish, search, navigation structure, hands-free cooking support, and grocery list functionality.

Users need:
- A beautiful, organized home screen to browse their recipes
- A hands-free cooking mode for use in the kitchen
- A consolidated grocery list built from recipe ingredients
- Smooth navigation between these surfaces

## Decision

### Navigation Structure

We adopted a **bottom navigation bar** with three tabs (Recipes, Grocery, Profile) using `NavigationBar` (Material 3). The shell screen uses `IndexedStack` to preserve state across tab switches. GoRouter handles deep linking to capture and recipe detail screens.

### Home Screen -- Recipe Grid

- **Search bar** at the top for filtering by title or tag
- **Auto-grouped sections**: Favorites first, then grouped by first tag, then untagged
- **Responsive grid**: Uses `SliverGrid` with `maxCrossAxisExtent` so tablets show 3+ columns while phones show 2
- **Favorite overlay**: Heart button on recipe cards for quick favoriting
- **Beautiful empty state** with prominent capture CTA

### Cooking Mode

- **Dark theme** with high contrast for kitchen readability
- **PageView** for step-by-step swipe navigation
- **Timer detection**: Regex-based parser detects patterns like "cook for X minutes" and offers an in-app countdown timer
- **Wakelock**: `wakelock_plus` package keeps screen awake during cooking
- **Ingredient checklist**: Bottom sheet overlay with tap-to-check ingredients
- **Progress bar**: Linear indicator showing current step position

### Grocery List

- **Client-side computation**: Grocery list is built entirely from recipe data already in memory. No dedicated backend endpoint needed for V1.
- **Intelligent merging**: Ingredients with the same name and compatible units are merged (e.g., "2 cups flour" + "1 cup flour" = "3 cups flour"). Unit normalization handles plurals and abbreviations.
- **Heuristic categorization**: Simple keyword matching assigns ingredients to categories (produce, dairy, meat, pantry, frozen, bakery). Not perfect, but good enough for grocery aisle grouping.
- **Recipe selector**: Horizontal chip row lets users pick which recipes to shop for

### User Recipe Views

- **PATCH /recipes/:id/user-view** endpoint added to the API for persisting favorites, saves, and notes
- **Local state** via `UserRecipeViewNotifier` for immediate UI feedback; sync to backend in future iteration
- **D1 upsert** with `ON CONFLICT ... DO UPDATE` for safe concurrent updates

## Alternatives Considered

### Server-side grocery list endpoint
We considered a `GET /grocery-list?recipe_ids=...` endpoint but decided against it for V1. Client-side computation is simpler, avoids a round trip, and the merging logic is straightforward. We can move this server-side if performance becomes an issue with large recipe counts.

### Separate cooking mode app/module
A dedicated cooking app was considered but rejected as over-engineering. A full-screen dark-themed screen within the same app achieves the same UX goals with less complexity.

### Wakelock via platform channels
We considered writing custom platform channel code but `wakelock_plus` is well-maintained and handles both iOS and Android cleanly.

## Consequences

- The app now has a complete, polished UX for the core recipe workflow: browse -> view -> cook -> shop
- Bottom navigation provides clear wayfinding between the three primary surfaces
- Timer detection is regex-based and may miss unusual time expressions; this can be improved with LLM assistance in future iterations
- Ingredient categorization uses keyword heuristics that won't be perfect for all ingredients; this is acceptable for V1
- The `wakelock_plus` dependency adds native platform code that may require updating with OS releases
