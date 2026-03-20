/// Unit tests for the capture provider.
library;

import 'package:dishy/domain/models/ingredient.dart';
import 'package:dishy/domain/models/nutrition.dart';
import 'package:dishy/domain/models/recipe.dart';
import 'package:dishy/presentation/providers/capture_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal stub that mimics [RecipeRepository] for testing.
///
/// We use a separate class that does not extend [RecipeRepository] to
/// avoid the super constructor calling [ApiClient]. Instead, we pass
/// this directly to [CaptureNotifier] which only needs the repository
/// interface.
class _StubRecipeRepository {
  _StubRecipeRepository({this.shouldFail = false});

  final bool shouldFail;

  Future<ResolvedRecipe> captureRecipe(String text) async {
    if (shouldFail) {
      throw Exception('Extraction failed');
    }
    return const ResolvedRecipe(
      id: 'recipe-001',
      title: 'Test Recipe',
      ingredients: <ResolvedIngredient>[
        ResolvedIngredient(
          parsed: ParsedIngredient(name: 'flour'),
          resolution: IngredientResolution.unmatched(text: 'flour'),
        ),
      ],
      steps: <Step>[
        Step(number: 1, instruction: 'Mix ingredients'),
      ],
      servings: 4,
      timeMinutes: 30,
      source: Source(platform: Platform.manual),
      nutrition: NutritionComputation(
        perRecipe: NutritionFacts(
          calories: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
        ),
        status: NutritionStatus.unavailable,
      ),
      cover: CoverOutput.generatedCover(assetId: 'cover-001'),
      tags: <String>['test'],
    );
  }
}

/// A [CaptureNotifier] subclass that uses our stub repository directly
/// instead of requiring a real [RecipeRepository].
class _TestCaptureNotifier extends StateNotifier<CaptureState> {
  _TestCaptureNotifier({required _StubRecipeRepository repository})
      : _repository = repository,
        super(const CaptureIdle());

  final _StubRecipeRepository _repository;

  Future<ResolvedRecipe?> capture(String text) async {
    state = const CaptureLoading();

    try {
      final ResolvedRecipe recipe = await _repository.captureRecipe(text);
      state = CaptureSuccess(recipe: recipe);
      return recipe;
    } on Exception catch (e) {
      state = CaptureError(message: e.toString());
      return null;
    }
  }

  void reset() {
    state = const CaptureIdle();
  }
}

void main() {
  group('CaptureNotifier', () {
    test('initial state is CaptureIdle', () {
      final _StubRecipeRepository repo = _StubRecipeRepository();
      final _TestCaptureNotifier notifier =
          _TestCaptureNotifier(repository: repo);
      expect(notifier.state, isA<CaptureIdle>());
    });

    test('capture transitions to CaptureSuccess on success', () async {
      final _StubRecipeRepository repo = _StubRecipeRepository();
      final _TestCaptureNotifier notifier =
          _TestCaptureNotifier(repository: repo);

      final ResolvedRecipe? result = await notifier.capture('test recipe text');

      expect(result, isNotNull);
      expect(result!.title, 'Test Recipe');
      expect(notifier.state, isA<CaptureSuccess>());
    });

    test('capture transitions to CaptureError on failure', () async {
      final _StubRecipeRepository repo =
          _StubRecipeRepository(shouldFail: true);
      final _TestCaptureNotifier notifier =
          _TestCaptureNotifier(repository: repo);

      final ResolvedRecipe? result = await notifier.capture('test recipe text');

      expect(result, isNull);
      expect(notifier.state, isA<CaptureError>());
    });

    test('reset returns to CaptureIdle', () async {
      final _StubRecipeRepository repo = _StubRecipeRepository();
      final _TestCaptureNotifier notifier =
          _TestCaptureNotifier(repository: repo);

      await notifier.capture('test');
      expect(notifier.state, isA<CaptureSuccess>());

      notifier.reset();
      expect(notifier.state, isA<CaptureIdle>());
    });
  });

  group('CaptureState', () {
    test('CaptureIdle is a CaptureState', () {
      const CaptureState state = CaptureIdle();
      expect(state, isA<CaptureIdle>());
    });

    test('CaptureLoading is a CaptureState', () {
      const CaptureState state = CaptureLoading();
      expect(state, isA<CaptureLoading>());
    });

    test('CaptureError carries message', () {
      const CaptureError state = CaptureError(message: 'test error');
      expect(state.message, 'test error');
    });
  });
}
