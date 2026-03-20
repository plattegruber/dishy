/// Unit tests for the timer detection utility.
library;

import 'package:dishy/core/utils/timer_detection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('detectTimer', () {
    test('detects minutes pattern', () {
      final DetectedTimer? timer = detectTimer('Cook for 15 minutes');
      expect(timer, isNotNull);
      expect(timer!.durationMinutes, 15);
      expect(timer.label, '15 min');
    });

    test('detects min abbreviation', () {
      final DetectedTimer? timer = detectTimer('Bake for 30 min');
      expect(timer, isNotNull);
      expect(timer!.durationMinutes, 30);
    });

    test('detects mins abbreviation', () {
      final DetectedTimer? timer = detectTimer('Simmer for 20 mins');
      expect(timer, isNotNull);
      expect(timer!.durationMinutes, 20);
    });

    test('detects hours pattern', () {
      final DetectedTimer? timer = detectTimer('Cook for 2 hours');
      expect(timer, isNotNull);
      expect(timer!.durationMinutes, 120);
      expect(timer.label, '2 hr');
    });

    test('detects hr abbreviation', () {
      final DetectedTimer? timer = detectTimer('Bake for 1 hr');
      expect(timer, isNotNull);
      expect(timer!.durationMinutes, 60);
    });

    test('detects combined hours and minutes', () {
      final DetectedTimer? timer =
          detectTimer('Roast for 1 hour and 30 minutes');
      expect(timer, isNotNull);
      expect(timer!.durationMinutes, 90);
      expect(timer.label, '1 hr 30 min');
    });

    test('detects range pattern (uses higher value)', () {
      final DetectedTimer? timer = detectTimer('Bake for 25 to 30 minutes');
      expect(timer, isNotNull);
      expect(timer!.durationMinutes, 30);
    });

    test('detects seconds pattern', () {
      final DetectedTimer? timer = detectTimer('Cook for 90 seconds');
      expect(timer, isNotNull);
      expect(timer!.durationMinutes, 2);
    });

    test('returns null when no time found', () {
      final DetectedTimer? timer = detectTimer('Mix the flour and sugar');
      expect(timer, isNull);
    });

    test('returns null for empty string', () {
      final DetectedTimer? timer = detectTimer('');
      expect(timer, isNull);
    });

    test('handles case insensitivity', () {
      final DetectedTimer? timer = detectTimer('COOK FOR 15 MINUTES');
      expect(timer, isNotNull);
      expect(timer!.durationMinutes, 15);
    });

    test('detects timer in longer instruction text', () {
      final DetectedTimer? timer = detectTimer(
        'Place the casserole in the preheated oven and bake for 45 minutes, or until golden brown.',
      );
      expect(timer, isNotNull);
      expect(timer!.durationMinutes, 45);
    });
  });
}
