/// Utility for detecting cooking timer durations from instruction text.
///
/// Parses natural language time expressions like "cook for 15 minutes",
/// "bake 30 min", "simmer for 1 hour" and extracts the duration in minutes.
library;

/// A detected timer duration within a recipe step.
class DetectedTimer {
  /// Creates a detected timer.
  const DetectedTimer({
    required this.durationMinutes,
    required this.label,
  });

  /// The duration in minutes.
  final int durationMinutes;

  /// A human-readable label for the timer (e.g., "15 min").
  final String label;
}

/// Attempts to detect a cooking timer from instruction text.
///
/// Returns a [DetectedTimer] if a time expression is found, or `null`
/// if none is detected.
///
/// Handles patterns:
/// - "X minutes", "X min", "X mins"
/// - "X hours", "X hour", "X hr", "X hrs"
/// - "X to Y minutes" (uses the higher value)
/// - Combined "X hour(s) and Y minute(s)"
DetectedTimer? detectTimer(String text) {
  final String lower = text.toLowerCase();

  // Pattern: "X hour(s) and Y minute(s)"
  final RegExp combinedPattern = RegExp(
    r'(\d+)\s*(?:hours?|hrs?)\s*(?:and\s*)?(\d+)\s*(?:minutes?|mins?)',
  );
  final RegExpMatch? combinedMatch = combinedPattern.firstMatch(lower);
  if (combinedMatch != null) {
    final int hours = int.tryParse(combinedMatch.group(1) ?? '') ?? 0;
    final int minutes = int.tryParse(combinedMatch.group(2) ?? '') ?? 0;
    final int total = hours * 60 + minutes;
    if (total > 0) {
      return DetectedTimer(
        durationMinutes: total,
        label: _formatDuration(total),
      );
    }
  }

  // Pattern: "X to Y minutes/hours" (range — use higher value)
  final RegExp rangePattern = RegExp(
    r'(\d+)\s*(?:to|-)\s*(\d+)\s*(?:minutes?|mins?|hours?|hrs?)',
  );
  final RegExpMatch? rangeMatch = rangePattern.firstMatch(lower);
  if (rangeMatch != null) {
    final int high = int.tryParse(rangeMatch.group(2) ?? '') ?? 0;
    final bool isHours = rangeMatch.group(0)?.contains(RegExp(r'hours?|hrs?')) ?? false;
    final int multiplier = isHours ? 60 : 1;
    final int total = high * multiplier;
    if (total > 0) {
      return DetectedTimer(
        durationMinutes: total,
        label: _formatDuration(total),
      );
    }
  }

  // Pattern: "X hours"
  final RegExp hourPattern = RegExp(r'(\d+)\s*(?:hours?|hrs?)');
  final RegExpMatch? hourMatch = hourPattern.firstMatch(lower);
  if (hourMatch != null) {
    final int hours = int.tryParse(hourMatch.group(1) ?? '') ?? 0;
    if (hours > 0) {
      return DetectedTimer(
        durationMinutes: hours * 60,
        label: _formatDuration(hours * 60),
      );
    }
  }

  // Pattern: "X minutes"
  final RegExp minutePattern = RegExp(r'(\d+)\s*(?:minutes?|mins?)');
  final RegExpMatch? minuteMatch = minutePattern.firstMatch(lower);
  if (minuteMatch != null) {
    final int minutes = int.tryParse(minuteMatch.group(1) ?? '') ?? 0;
    if (minutes > 0) {
      return DetectedTimer(
        durationMinutes: minutes,
        label: _formatDuration(minutes),
      );
    }
  }

  // Pattern: "X seconds" (convert to 1 min minimum)
  final RegExp secondPattern = RegExp(r'(\d+)\s*(?:seconds?|secs?)');
  final RegExpMatch? secondMatch = secondPattern.firstMatch(lower);
  if (secondMatch != null) {
    final int seconds = int.tryParse(secondMatch.group(1) ?? '') ?? 0;
    if (seconds > 0) {
      final int minutes = (seconds / 60).ceil().clamp(1, 999);
      return DetectedTimer(
        durationMinutes: minutes,
        label: _formatDuration(minutes),
      );
    }
  }

  return null;
}

/// Formats a duration in minutes as a human-readable string.
String _formatDuration(int minutes) {
  if (minutes >= 60) {
    final int hours = minutes ~/ 60;
    final int mins = minutes % 60;
    if (mins == 0) {
      return '$hours hr';
    }
    return '$hours hr $mins min';
  }
  return '$minutes min';
}
