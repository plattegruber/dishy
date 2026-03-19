import 'package:dishy/domain/models/pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CapturePipelineState', () {
    test('has all expected values', () {
      expect(CapturePipelineState.values, hasLength(6));
    });

    test('received can transition to processing', () {
      expect(
        CapturePipelineState.received
            .canTransitionTo(CapturePipelineState.processing),
        isTrue,
      );
    });

    test('received cannot transition to extracted', () {
      expect(
        CapturePipelineState.received
            .canTransitionTo(CapturePipelineState.extracted),
        isFalse,
      );
    });

    test('received cannot transition to resolved', () {
      expect(
        CapturePipelineState.received
            .canTransitionTo(CapturePipelineState.resolved),
        isFalse,
      );
    });

    test('processing can transition to extracted', () {
      expect(
        CapturePipelineState.processing
            .canTransitionTo(CapturePipelineState.extracted),
        isTrue,
      );
    });

    test('processing can transition to failed', () {
      expect(
        CapturePipelineState.processing
            .canTransitionTo(CapturePipelineState.failed),
        isTrue,
      );
    });

    test('extracted can transition to needsReview', () {
      expect(
        CapturePipelineState.extracted
            .canTransitionTo(CapturePipelineState.needsReview),
        isTrue,
      );
    });

    test('extracted can transition to resolved', () {
      expect(
        CapturePipelineState.extracted
            .canTransitionTo(CapturePipelineState.resolved),
        isTrue,
      );
    });

    test('extracted can transition to failed', () {
      expect(
        CapturePipelineState.extracted
            .canTransitionTo(CapturePipelineState.failed),
        isTrue,
      );
    });

    test('needsReview can transition to resolved', () {
      expect(
        CapturePipelineState.needsReview
            .canTransitionTo(CapturePipelineState.resolved),
        isTrue,
      );
    });

    test('needsReview can transition to failed', () {
      expect(
        CapturePipelineState.needsReview
            .canTransitionTo(CapturePipelineState.failed),
        isTrue,
      );
    });

    test('resolved is terminal', () {
      expect(CapturePipelineState.resolved.isTerminal, isTrue);
      expect(CapturePipelineState.resolved.validTransitions, isEmpty);
    });

    test('failed is terminal', () {
      expect(CapturePipelineState.failed.isTerminal, isTrue);
      expect(CapturePipelineState.failed.validTransitions, isEmpty);
    });

    test('received is not terminal', () {
      expect(CapturePipelineState.received.isTerminal, isFalse);
    });
  });

  group('NutritionState', () {
    test('has all expected values', () {
      expect(NutritionState.values, hasLength(4));
    });

    test('pending can transition to calculated', () {
      expect(
        NutritionState.pending.canTransitionTo(NutritionState.calculated),
        isTrue,
      );
    });

    test('pending can transition to estimated', () {
      expect(
        NutritionState.pending.canTransitionTo(NutritionState.estimated),
        isTrue,
      );
    });

    test('pending can transition to unavailable', () {
      expect(
        NutritionState.pending.canTransitionTo(NutritionState.unavailable),
        isTrue,
      );
    });

    test('pending is not terminal', () {
      expect(NutritionState.pending.isTerminal, isFalse);
    });

    test('calculated is terminal', () {
      expect(NutritionState.calculated.isTerminal, isTrue);
      expect(NutritionState.calculated.validTransitions, isEmpty);
    });

    test('estimated is terminal', () {
      expect(NutritionState.estimated.isTerminal, isTrue);
    });

    test('unavailable is terminal', () {
      expect(NutritionState.unavailable.isTerminal, isTrue);
    });

    test('calculated cannot transition to estimated', () {
      expect(
        NutritionState.calculated.canTransitionTo(NutritionState.estimated),
        isFalse,
      );
    });
  });
}
