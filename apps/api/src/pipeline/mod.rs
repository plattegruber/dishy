//! Recipe capture pipeline contracts from SPEC §9.
//!
//! This module defines the typed function signatures for each stage of the
//! capture → extract → structure → resolve → assemble pipeline. These are
//! currently stub implementations that return placeholder data or errors.
//! The real implementations will be wired up in later phases.
//!
//! Each function is idempotent and produces immutable outputs per SPEC §4.

pub mod contracts;
pub mod errors;
pub mod queue;
