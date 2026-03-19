/// Structured logging service for the Dishy mobile app.
///
/// Produces JSON log entries that match the shared cross-platform schema
/// used by both the Flutter client and the Rust API, enabling correlation
/// in Axiom. Entries are buffered in memory and periodically flushed to
/// the Axiom ingest API via [AxiomTransport].
library;

import 'dart:collection';

import 'package:uuid/uuid.dart';

/// Severity levels matching the shared log schema.
enum LogLevel {
  /// Verbose debugging information.
  debug('debug'),

  /// Normal operational events.
  info('info'),

  /// Potential issues that do not prevent operation.
  warn('warn'),

  /// Failures that need attention.
  error('error');

  const LogLevel(this.value);

  /// Serialized string value used in JSON log entries.
  final String value;
}

/// A single structured log entry matching the cross-platform schema.
///
/// Both the Rust API and the Flutter mobile app produce entries with this
/// shape so they can be queried together in Axiom.
class LogEntry {
  /// Creates a new log entry.
  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    required this.correlationId,
    required this.sessionId,
    required this.service,
    required this.context,
  });

  /// ISO-8601 timestamp of when the log was created.
  final String timestamp;

  /// Severity level.
  final LogLevel level;

  /// Human-readable log message.
  final String message;

  /// UUIDv4 correlation ID linking related operations across services.
  final String correlationId;

  /// UUIDv4 session ID identifying the client session.
  final String sessionId;

  /// Service that produced this entry (`"api"` or `"mobile"`).
  final String service;

  /// Arbitrary structured data for additional context.
  final Map<String, Object> context;

  /// Serializes this entry to a JSON-compatible map.
  Map<String, Object> toJson() {
    return <String, Object>{
      'timestamp': timestamp,
      'level': level.value,
      'message': message,
      'correlation_id': correlationId,
      'session_id': sessionId,
      'service': service,
      'context': context,
    };
  }
}

/// Structured logging service that buffers entries and flushes them
/// in batches.
///
/// Use [LogService.debug], [LogService.info], [LogService.warn], and
/// [LogService.error] to record log entries. Call [flush] to retrieve
/// all buffered entries (e.g. for sending to Axiom).
class LogService {
  /// Creates a [LogService] with the given [sessionId].
  ///
  /// The [sessionId] is a UUIDv4 generated once per app session and
  /// attached to every log entry for session-level correlation.
  LogService({required this.sessionId});

  /// UUIDv4 identifying the current app session.
  final String sessionId;

  /// UUID generator for correlation IDs.
  static const Uuid _uuid = Uuid();

  /// Internal buffer of log entries waiting to be flushed.
  final List<LogEntry> _buffer = <LogEntry>[];

  /// Returns an unmodifiable view of the current buffered entries.
  UnmodifiableListView<LogEntry> get entries =>
      UnmodifiableListView<LogEntry>(_buffer);

  /// Returns the number of buffered entries.
  int get entryCount => _buffer.length;

  /// Generates a new UUIDv4 correlation ID.
  ///
  /// Call this once per API request or user action to get a fresh
  /// correlation ID that links frontend and backend logs.
  static String generateCorrelationId() => _uuid.v4();

  /// Logs a debug-level message.
  void debug(
    String message, {
    String? correlationId,
    Map<String, Object>? context,
  }) {
    _log(LogLevel.debug, message,
        correlationId: correlationId, context: context);
  }

  /// Logs an info-level message.
  void info(
    String message, {
    String? correlationId,
    Map<String, Object>? context,
  }) {
    _log(LogLevel.info, message,
        correlationId: correlationId, context: context);
  }

  /// Logs a warn-level message.
  void warn(
    String message, {
    String? correlationId,
    Map<String, Object>? context,
  }) {
    _log(LogLevel.warn, message,
        correlationId: correlationId, context: context);
  }

  /// Logs an error-level message.
  void error(
    String message, {
    String? correlationId,
    Map<String, Object>? context,
  }) {
    _log(LogLevel.error, message,
        correlationId: correlationId, context: context);
  }

  /// Drains all buffered entries and returns them.
  ///
  /// After calling this method the internal buffer is empty. The caller
  /// is responsible for sending the returned entries to Axiom via
  /// [AxiomTransport].
  List<LogEntry> flush() {
    final List<LogEntry> flushed = List<LogEntry>.of(_buffer);
    _buffer.clear();
    return flushed;
  }

  /// Internal helper that creates and buffers a log entry.
  void _log(
    LogLevel level,
    String message, {
    String? correlationId,
    Map<String, Object>? context,
  }) {
    final LogEntry entry = LogEntry(
      timestamp: DateTime.now().toUtc().toIso8601String(),
      level: level,
      message: message,
      correlationId: correlationId ?? generateCorrelationId(),
      sessionId: sessionId,
      service: 'mobile',
      context: context ?? const <String, Object>{},
    );
    _buffer.add(entry);
  }
}
