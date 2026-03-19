//! Structured logging with Axiom integration.
//!
//! Provides a [`Logger`] that buffers structured JSON log entries during a
//! request and flushes them to the Axiom ingest API at the end. Each log
//! entry carries a correlation ID, session ID, timestamp, level, message,
//! and optional structured context so that frontend and backend logs can be
//! correlated in Axiom.
//!
//! Log entries are emitted locally via `console_log!` for Cloudflare
//! dashboard visibility **and** batched for Axiom ingestion.

use chrono::Utc;
use serde::{Deserialize, Serialize};
use std::cell::RefCell;
use std::collections::HashMap;

/// Log severity levels matching the shared contract.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum LogLevel {
    /// Verbose debugging information (not sent to Axiom in production).
    Debug,
    /// Normal operational events.
    Info,
    /// Potential issues that do not prevent operation.
    Warn,
    /// Failures that need attention.
    Error,
}

impl std::fmt::Display for LogLevel {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            LogLevel::Debug => write!(f, "debug"),
            LogLevel::Info => write!(f, "info"),
            LogLevel::Warn => write!(f, "warn"),
            LogLevel::Error => write!(f, "error"),
        }
    }
}

/// A single structured log entry matching the shared cross-platform schema.
///
/// Both the Rust API and the Flutter mobile app produce entries with this
/// shape so they can be queried together in Axiom.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LogEntry {
    /// ISO-8601 timestamp of when the log was created.
    pub timestamp: String,
    /// Severity level.
    pub level: LogLevel,
    /// Human-readable log message.
    pub message: String,
    /// UUIDv4 correlation ID linking related operations across services.
    pub correlation_id: String,
    /// UUIDv4 session ID identifying the client session.
    pub session_id: String,
    /// Service that produced this entry (`"api"` or `"mobile"`).
    pub service: String,
    /// Arbitrary structured data for additional context.
    pub context: HashMap<String, serde_json::Value>,
}

/// Per-request log buffer that collects entries and flushes them to Axiom.
///
/// Create one [`Logger`] per incoming request. Call the level-specific
/// methods ([`Logger::info`], [`Logger::warn`], etc.) during request
/// processing, then call [`Logger::flush`] at the end to send the batch
/// to Axiom.
pub struct Logger {
    /// Buffered log entries waiting to be flushed.
    entries: RefCell<Vec<LogEntry>>,
    /// Correlation ID for the current request.
    correlation_id: String,
    /// Session ID from the client (or empty if not provided).
    session_id: String,
}

impl Logger {
    /// Creates a new logger for a single request.
    ///
    /// # Arguments
    ///
    /// * `correlation_id` — UUIDv4 identifying this request across services.
    /// * `session_id` — UUIDv4 identifying the client session, or an empty
    ///   string if the client did not send one.
    pub fn new(correlation_id: String, session_id: String) -> Self {
        Self {
            entries: RefCell::new(Vec::new()),
            correlation_id,
            session_id,
        }
    }

    /// Logs a debug-level message.
    pub fn debug(&self, message: &str, context: HashMap<String, serde_json::Value>) {
        self.log(LogLevel::Debug, message, context);
    }

    /// Logs an info-level message.
    pub fn info(&self, message: &str, context: HashMap<String, serde_json::Value>) {
        self.log(LogLevel::Info, message, context);
    }

    /// Logs a warn-level message.
    pub fn warn(&self, message: &str, context: HashMap<String, serde_json::Value>) {
        self.log(LogLevel::Warn, message, context);
    }

    /// Logs an error-level message.
    pub fn error(&self, message: &str, context: HashMap<String, serde_json::Value>) {
        self.log(LogLevel::Error, message, context);
    }

    /// Returns the number of buffered entries.
    pub fn entry_count(&self) -> usize {
        self.entries.borrow().len()
    }

    /// Returns the correlation ID associated with this logger.
    pub fn correlation_id(&self) -> &str {
        &self.correlation_id
    }

    /// Returns the session ID associated with this logger.
    pub fn session_id(&self) -> &str {
        &self.session_id
    }

    /// Flushes all buffered log entries to Axiom via the ingest API.
    ///
    /// Entries are sent as newline-delimited JSON (NDJSON) to
    /// `POST https://api.axiom.co/v1/datasets/{dataset}/ingest`.
    ///
    /// The flush is best-effort: if the Axiom request fails the entries
    /// are lost, but the original HTTP request is not affected. Entries
    /// have already been written to `console_log!` so they remain visible
    /// in the Cloudflare dashboard regardless.
    ///
    /// Returns the number of entries that were flushed.
    pub async fn flush(&self, axiom_token: &str, axiom_dataset: &str) -> Result<usize, LogError> {
        let entries = self.entries.borrow().clone();
        if entries.is_empty() {
            return Ok(0);
        }

        let count = entries.len();

        // Build NDJSON body
        let ndjson = entries
            .iter()
            .filter_map(|entry| serde_json::to_string(entry).ok())
            .collect::<Vec<String>>()
            .join("\n");

        let url = format!("https://api.axiom.co/v1/datasets/{}/ingest", axiom_dataset);

        // Use the worker Fetch API to send logs to Axiom
        let headers = worker::Headers::new();
        headers
            .set("Authorization", &format!("Bearer {}", axiom_token))
            .map_err(|e| LogError::Transport(format!("failed to set auth header: {e}")))?;
        headers
            .set("Content-Type", "application/x-ndjson")
            .map_err(|e| LogError::Transport(format!("failed to set content-type: {e}")))?;

        let request = worker::Request::new_with_init(
            &url,
            worker::RequestInit::new()
                .with_method(worker::Method::Post)
                .with_headers(headers)
                .with_body(Some(worker::wasm_bindgen::JsValue::from_str(&ndjson))),
        )
        .map_err(|e| LogError::Transport(format!("failed to build request: {e}")))?;

        match worker::Fetch::Request(request).send().await {
            Ok(mut resp) => {
                if resp.status_code() >= 400 {
                    let body = resp.text().await.unwrap_or_default();
                    #[cfg(target_arch = "wasm32")]
                    worker::console_log!(
                        "[logging] Axiom ingest failed ({}): {}",
                        resp.status_code(),
                        body
                    );
                    return Err(LogError::AxiomError {
                        status: resp.status_code(),
                        body,
                    });
                }
                Ok(count)
            }
            Err(e) => {
                #[cfg(target_arch = "wasm32")]
                worker::console_log!("[logging] Axiom ingest request failed: {e}");
                Err(LogError::Transport(format!(
                    "Axiom ingest request failed: {e}"
                )))
            }
        }
    }

    /// Internal helper to create, buffer, and console-log a single entry.
    fn log(&self, level: LogLevel, message: &str, context: HashMap<String, serde_json::Value>) {
        let entry = LogEntry {
            timestamp: Utc::now().to_rfc3339(),
            level,
            message: message.to_string(),
            correlation_id: self.correlation_id.clone(),
            session_id: self.session_id.clone(),
            service: "api".to_string(),
            context,
        };

        // Always emit to console for Cloudflare dashboard (wasm only)
        #[cfg(target_arch = "wasm32")]
        if let Ok(json) = serde_json::to_string(&entry) {
            worker::console_log!("{}", json);
        }

        self.entries.borrow_mut().push(entry);
    }
}

/// Errors that can occur during log flushing.
#[derive(Debug)]
pub enum LogError {
    /// A transport-level error (network, request construction).
    Transport(String),
    /// Axiom returned a non-success HTTP status.
    AxiomError {
        /// HTTP status code from Axiom.
        status: u16,
        /// Response body from Axiom.
        body: String,
    },
}

impl std::fmt::Display for LogError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            LogError::Transport(msg) => write!(f, "log transport error: {msg}"),
            LogError::AxiomError { status, body } => {
                write!(f, "Axiom ingest error (HTTP {status}): {body}")
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn log_entry_serializes_to_expected_schema() {
        let entry = LogEntry {
            timestamp: "2026-03-19T12:00:00+00:00".to_string(),
            level: LogLevel::Info,
            message: "test message".to_string(),
            correlation_id: "550e8400-e29b-41d4-a716-446655440000".to_string(),
            session_id: "660e8400-e29b-41d4-a716-446655440000".to_string(),
            service: "api".to_string(),
            context: HashMap::new(),
        };

        let json = serde_json::to_string(&entry).expect("serialization should succeed");
        let parsed: serde_json::Value = serde_json::from_str(&json).expect("should be valid JSON");

        assert_eq!(parsed["timestamp"], "2026-03-19T12:00:00+00:00");
        assert_eq!(parsed["level"], "info");
        assert_eq!(parsed["message"], "test message");
        assert_eq!(
            parsed["correlation_id"],
            "550e8400-e29b-41d4-a716-446655440000"
        );
        assert_eq!(parsed["session_id"], "660e8400-e29b-41d4-a716-446655440000");
        assert_eq!(parsed["service"], "api");
        assert!(parsed["context"].is_object());
    }

    #[test]
    fn log_entry_with_context_serializes_correctly() {
        let mut context = HashMap::new();
        context.insert(
            "method".to_string(),
            serde_json::Value::String("GET".to_string()),
        );
        context.insert("status_code".to_string(), serde_json::json!(200));

        let entry = LogEntry {
            timestamp: "2026-03-19T12:00:00+00:00".to_string(),
            level: LogLevel::Warn,
            message: "slow request".to_string(),
            correlation_id: "test-corr-id".to_string(),
            session_id: "test-sess-id".to_string(),
            service: "api".to_string(),
            context,
        };

        let json = serde_json::to_string(&entry).expect("serialization should succeed");
        let parsed: serde_json::Value = serde_json::from_str(&json).expect("should be valid JSON");

        assert_eq!(parsed["level"], "warn");
        assert_eq!(parsed["context"]["method"], "GET");
        assert_eq!(parsed["context"]["status_code"], 200);
    }

    #[test]
    fn log_level_display_matches_serde_name() {
        assert_eq!(LogLevel::Debug.to_string(), "debug");
        assert_eq!(LogLevel::Info.to_string(), "info");
        assert_eq!(LogLevel::Warn.to_string(), "warn");
        assert_eq!(LogLevel::Error.to_string(), "error");
    }

    #[test]
    fn log_level_deserializes_from_lowercase_string() {
        let debug: LogLevel = serde_json::from_str("\"debug\"").expect("should parse debug");
        assert_eq!(debug, LogLevel::Debug);

        let error: LogLevel = serde_json::from_str("\"error\"").expect("should parse error");
        assert_eq!(error, LogLevel::Error);
    }

    #[test]
    fn logger_buffers_entries() {
        let logger = Logger::new("corr-123".to_string(), "sess-456".to_string());
        assert_eq!(logger.entry_count(), 0);

        logger.info("first", HashMap::new());
        assert_eq!(logger.entry_count(), 1);

        logger.warn("second", HashMap::new());
        assert_eq!(logger.entry_count(), 2);

        logger.error("third", HashMap::new());
        assert_eq!(logger.entry_count(), 3);

        logger.debug("fourth", HashMap::new());
        assert_eq!(logger.entry_count(), 4);
    }

    #[test]
    fn logger_preserves_correlation_and_session_ids() {
        let logger = Logger::new("my-corr-id".to_string(), "my-sess-id".to_string());

        assert_eq!(logger.correlation_id(), "my-corr-id");
        assert_eq!(logger.session_id(), "my-sess-id");

        logger.info("test", HashMap::new());

        let entries = logger.entries.borrow();
        assert_eq!(entries[0].correlation_id, "my-corr-id");
        assert_eq!(entries[0].session_id, "my-sess-id");
        assert_eq!(entries[0].service, "api");
    }

    #[test]
    fn logger_entries_have_correct_levels() {
        let logger = Logger::new("c".to_string(), "s".to_string());

        logger.debug("d", HashMap::new());
        logger.info("i", HashMap::new());
        logger.warn("w", HashMap::new());
        logger.error("e", HashMap::new());

        let entries = logger.entries.borrow();
        assert_eq!(entries[0].level, LogLevel::Debug);
        assert_eq!(entries[1].level, LogLevel::Info);
        assert_eq!(entries[2].level, LogLevel::Warn);
        assert_eq!(entries[3].level, LogLevel::Error);
    }

    #[test]
    fn log_error_display_formats_correctly() {
        let transport = LogError::Transport("connection refused".to_string());
        assert_eq!(
            transport.to_string(),
            "log transport error: connection refused"
        );

        let axiom = LogError::AxiomError {
            status: 403,
            body: "forbidden".to_string(),
        };
        assert_eq!(
            axiom.to_string(),
            "Axiom ingest error (HTTP 403): forbidden"
        );
    }
}
