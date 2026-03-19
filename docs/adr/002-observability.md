# ADR-002: Observability — Structured Logging with Axiom and Correlation IDs

**Status:** Accepted
**Date:** 2026-03-19
**Deciders:** Project team

## Context

Dishy is a multi-stage pipeline (Capture, Extract, Structure, Enrich, Present) that spans a Rust Cloudflare Worker backend and a Flutter mobile frontend. When something goes wrong — a slow extraction, a failed API call, or an unexpected user flow — we need to trace a single user action through both systems.

Without structured logging and cross-service correlation, debugging requires manually stitching together Cloudflare console logs and client-side print statements, which is impractical at any scale.

## Decision

### Structured Logging to Axiom

All logs from both the Rust API and the Flutter mobile app are structured JSON entries sent to Axiom via its HTTP ingest API (`POST https://api.axiom.co/v1/datasets/{dataset}/ingest`).

Each entry follows a shared schema:

```json
{
  "timestamp": "ISO-8601",
  "level": "debug|info|warn|error",
  "message": "human-readable text",
  "correlation_id": "UUIDv4",
  "session_id": "UUIDv4",
  "service": "api|mobile",
  "context": {}
}
```

Logs are separated into two Axiom datasets:
- `dishy-api` — backend Worker logs
- `dishy-mobile` — frontend client logs

### Correlation ID Scheme

- **Correlation ID:** A UUIDv4 generated per logical operation (typically one per HTTP request). The mobile app generates the correlation ID and sends it as `X-Correlation-ID` in every API request. The backend reads this header and attaches the same ID to all of its log entries for that request. If the header is missing (e.g. health check from a monitoring system), the backend generates its own.

- **Session ID:** A UUIDv4 generated once per app session (in-memory only, not persisted). Sent as `X-Session-ID` on every request. Allows grouping all logs from a single user session.

Both IDs are propagated via HTTP headers and included in every log entry on both sides, enabling Axiom queries like:

```
correlation_id == "abc-123"
```

to return the full trace of a single user action across frontend and backend.

### Backend Implementation

- `logging.rs` — `Logger` struct that buffers `LogEntry` instances per request and flushes them to Axiom as NDJSON at the end of each request. Also emits entries via `console_log!` for Cloudflare dashboard visibility.
- `middleware.rs` — `extract_request_context()` reads `X-Correlation-ID` and `X-Session-ID` from request headers, creates a `Logger`, and returns a `RequestContext`. `attach_correlation_header()` echoes the correlation ID back on responses.
- Axiom token is stored as a Cloudflare secret (`AXIOM_API_TOKEN`), dataset name as a `[vars]` binding in `wrangler.toml`.

### Frontend Implementation

- `log_service.dart` — `LogService` class that buffers `LogEntry` instances and exposes `flush()` to drain them for transport.
- `axiom_transport.dart` — `AxiomTransport` class that sends batched entries to Axiom via Dio.
- `correlation_provider.dart` — Riverpod providers for `sessionId` (stable per app session) and `logService` (shared instance).
- `api_client.dart` — `CorrelationInterceptor` that attaches `X-Correlation-ID` and `X-Session-ID` headers to every outgoing Dio request and logs the request/response lifecycle.

### Why Axiom

- **Simple HTTP ingest:** No SDK or agent required. A single POST with NDJSON is all it takes.
- **Generous free tier:** 500 GB ingest/month, sufficient for early development.
- **Structured query language:** Enables filtering by correlation ID, session ID, service, level, and any context field.
- **Already in the tech stack:** Selected in ADR-001.

### Why Not Cloudflare Logpush / Workers Analytics

- Logpush is designed for high-volume access logs, not structured application logs.
- Workers Analytics Engine is good for metrics but not for free-text log search and correlation.
- Axiom gives us a single pane of glass across both the Worker and the mobile app.

## Consequences

### Positive

- **End-to-end traceability:** Any user action can be traced from the Flutter UI through the API and back.
- **Consistent schema:** Both platforms produce identical log shapes, simplifying Axiom queries.
- **Best-effort logging:** Log failures never block request processing or degrade user experience.
- **Low overhead:** Logs are buffered per-request and flushed in a single HTTP call.

### Negative

- **Axiom dependency:** If Axiom is down, logs for that period are lost (they remain in Cloudflare console but not queryable).
- **Latency cost:** The Axiom flush adds one outbound HTTP request at the end of each Worker invocation. Mitigated by the Worker's global edge distribution.
- **Token management:** The Axiom API token must be set as a Cloudflare secret and a Flutter build-time define, adding to the deployment checklist.

### Risks

- If Axiom changes their ingest API, both the Rust and Dart clients need updating.
- High-volume logging could approach the free tier limits; may need log sampling in the future.

## References

- [Axiom Ingest API](https://axiom.co/docs/send-data/ingest)
- [Cloudflare Workers Observability](https://developers.cloudflare.com/workers/observability/)
- [ADR-001: Tech Stack Selection](001-tech-stack.md)
