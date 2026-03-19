/// Application-wide constants.
///
/// Centralises magic strings and configuration values so they can be
/// changed in one place. Environment-specific overrides should be
/// handled via build flavors, not by modifying these defaults.
library;

/// Static constants used throughout the Dishy application.
abstract final class AppConstants {
  /// Base URL for the Dishy Worker API.
  ///
  /// Defaults to the production Cloudflare Worker URL.
  /// Override with `--dart-define=API_BASE_URL=http://localhost:8787`
  /// when running against a local `wrangler dev` instance.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dishy-api.workers.dev',
  );

  /// Application display name.
  static const String appName = 'Dishy';

  /// Axiom dataset name for mobile client logs.
  ///
  /// Override with `--dart-define=AXIOM_DATASET=custom-name` if needed.
  static const String axiomDataset = String.fromEnvironment(
    'AXIOM_DATASET',
    defaultValue: 'dishy-mobile',
  );

  /// Axiom API token for log ingestion.
  ///
  /// Must be set via `--dart-define=AXIOM_API_TOKEN=<token>` at build
  /// time. When empty, log flushing to Axiom is skipped.
  static const String axiomApiToken = String.fromEnvironment(
    'AXIOM_API_TOKEN',
  );
}
