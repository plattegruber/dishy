//! Database module for Cloudflare D1 interactions.
//!
//! Provides typed query functions that map between the D1 SQLite database
//! and the Rust domain types. All queries use parameterised statements
//! to prevent SQL injection.
//!
//! ## Schema
//!
//! The D1 database schema is defined in `schema.sql` and applied via
//! migrations in the `migrations/` directory. Run migrations with:
//!
//! ```bash
//! npx wrangler d1 migrations apply DB
//! ```

pub mod queries;
