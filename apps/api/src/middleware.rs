//! Request middleware for correlation ID propagation and logging context.
//!
//! Extracts `X-Correlation-ID` and `X-Session-ID` headers from incoming
//! requests (generating a UUIDv4 for the correlation ID if none is
//! provided). These IDs are attached to a [`RequestContext`] that handlers
//! use throughout the request lifecycle, and the correlation ID is echoed
//! back on every response.

use uuid::Uuid;
use worker::Request;

use crate::logging::Logger;

/// Header name for the correlation ID.
pub const CORRELATION_ID_HEADER: &str = "X-Correlation-ID";

/// Header name for the session ID.
pub const SESSION_ID_HEADER: &str = "X-Session-ID";

/// Per-request context carrying correlation metadata and a logger.
///
/// Created by [`extract_request_context`] at the start of every request.
/// Handlers use the embedded [`Logger`] for structured logging and read
/// the IDs when they need to propagate context to downstream services.
pub struct RequestContext {
    /// UUIDv4 correlation ID for this request (from header or generated).
    pub correlation_id: String,
    /// UUIDv4 session ID from the client, empty string if not provided.
    pub session_id: String,
    /// Structured logger pre-configured with the request's IDs.
    pub logger: Logger,
}

/// Extracts correlation and session IDs from request headers and builds
/// a [`RequestContext`].
///
/// If the `X-Correlation-ID` header is missing or empty, a new UUIDv4 is
/// generated. The `X-Session-ID` header is optional; when absent the
/// session ID defaults to an empty string.
///
/// # Arguments
///
/// * `req` — The incoming Worker request.
///
/// # Returns
///
/// A [`RequestContext`] ready for use by route handlers.
pub fn extract_request_context(req: &Request) -> RequestContext {
    let headers = req.headers();

    let correlation_id = headers
        .get(CORRELATION_ID_HEADER)
        .ok()
        .flatten()
        .filter(|v| !v.is_empty())
        .unwrap_or_else(|| Uuid::new_v4().to_string());

    let session_id = headers
        .get(SESSION_ID_HEADER)
        .ok()
        .flatten()
        .unwrap_or_default();

    let logger = Logger::new(correlation_id.clone(), session_id.clone());

    RequestContext {
        correlation_id,
        session_id,
        logger,
    }
}

/// Attaches the correlation ID to an outgoing response.
///
/// Adds the `X-Correlation-ID` header so clients and downstream
/// consumers can correlate the response with request-side logs.
///
/// # Errors
///
/// Returns the original `worker::Error` if header mutation fails.
pub fn attach_correlation_header(
    response: &mut worker::Response,
    correlation_id: &str,
) -> Result<(), worker::Error> {
    response
        .headers_mut()
        .set(CORRELATION_ID_HEADER, correlation_id)?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn correlation_id_header_constant_is_correct() {
        assert_eq!(CORRELATION_ID_HEADER, "X-Correlation-ID");
    }

    #[test]
    fn session_id_header_constant_is_correct() {
        assert_eq!(SESSION_ID_HEADER, "X-Session-ID");
    }

    #[test]
    fn generated_correlation_id_is_valid_uuid() {
        let id = Uuid::new_v4().to_string();
        assert!(Uuid::parse_str(&id).is_ok(), "should be a valid UUID");
        assert_eq!(id.len(), 36, "UUID string should be 36 chars");
    }
}
