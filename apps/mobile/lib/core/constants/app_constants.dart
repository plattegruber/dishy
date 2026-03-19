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
}
