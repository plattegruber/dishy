/// Riverpod providers for correlation ID and session management.
///
/// Exposes a [sessionIdProvider] that generates a UUIDv4 once per app
/// session (kept in memory — not persisted across restarts) and a
/// [logServiceProvider] that gives every consumer access to the shared
/// [LogService] instance pre-configured with the session ID.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'log_service.dart';

/// UUID generator used for session IDs.
const Uuid _uuid = Uuid();

/// Provides a stable UUIDv4 session ID for the lifetime of the app.
///
/// The session ID is generated once when the provider is first read and
/// remains constant until the app process is killed. It is attached to
/// every log entry and sent as the `X-Session-ID` HTTP header so that
/// all frontend and backend logs for a single user session can be
/// correlated in Axiom.
final Provider<String> sessionIdProvider = Provider<String>(
  (Ref ref) => _uuid.v4(),
);

/// Provides the shared [LogService] instance.
///
/// The service is pre-configured with the session ID from
/// [sessionIdProvider]. Inject this provider into any widget, service,
/// or interceptor that needs to produce structured log entries.
final Provider<LogService> logServiceProvider = Provider<LogService>(
  (Ref ref) {
    final String sessionId = ref.watch(sessionIdProvider);
    return LogService(sessionId: sessionId);
  },
);
