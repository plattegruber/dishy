//! Business logic services for the Dishy API.
//!
//! Each service encapsulates a specific domain concern and is called
//! from route handlers. Services do not access the D1 database directly —
//! they accept typed domain structs and return typed results.
//!
//! - [`extraction`] — Recipe extraction via Claude API
//! - [`storage`] — Image upload and retrieval from Cloudflare R2
//! - [`cover`] — Cover image generation and selection

pub mod cover;
pub mod extraction;
pub mod storage;
