//! Business logic services for the Dishy API.
//!
//! Each service encapsulates a specific domain concern and is called
//! from route handlers. Services do not access the D1 database directly —
//! they accept typed domain structs and return typed results.

pub mod extraction;
pub mod ingredient_parser;
pub mod ingredient_resolver;
pub mod nutrition;
pub mod ocr;
pub mod social;
