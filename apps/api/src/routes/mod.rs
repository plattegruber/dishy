//! HTTP route handlers for the Dishy API.
//!
//! Each route module corresponds to a SPEC section or resource type.
//! Route handlers authenticate requests, parse bodies, delegate to
//! services and the pipeline, persist to D1, and return JSON responses.

pub mod images;
pub mod recipes;
