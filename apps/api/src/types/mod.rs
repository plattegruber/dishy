//! Domain types from SPEC §8.
//!
//! This module contains the complete domain model for Dishy, organized
//! by the spec sections they map to:
//!
//! - [`ids`] — Branded ID types (RecipeId, CaptureId, UserId, etc.)
//! - [`capture`] — Capture inputs and extraction artifacts (§8.1)
//! - [`ingredient`] — Ingredient parsing and resolution (§8.2)
//! - [`nutrition`] — Nutrition facts and computation (§8.3)
//! - [`recipe`] — Recipes, sources, covers, and user views (§8.3, §8.4)
//! - [`pipeline`] — Pipeline state machines (§10)

pub mod capture;
pub mod ids;
pub mod ingredient;
pub mod nutrition;
pub mod pipeline;
pub mod recipe;
