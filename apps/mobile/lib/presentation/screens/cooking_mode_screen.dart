/// Cooking mode screen -- hands-free step-by-step recipe view.
///
/// Features:
/// - Large text, high contrast for kitchen use
/// - Step-by-step navigation (swipe or tap)
/// - Automatic timer detection with in-app timer
/// - Ingredient checklist with tap to cross off
/// - Screen stays awake via wakelock_plus
///
/// Implements SPEC section 15: "Recipe View: hands-free cooking mode".
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/utils/timer_detection.dart';
import '../../domain/models/ingredient.dart';
import '../../domain/models/recipe.dart' as recipe_model;
import '../../domain/models/recipe.dart' hide Step;

/// Full-screen cooking mode for a recipe.
///
/// Keeps the screen awake and shows one step at a time with large,
/// readable text. Supports swipe/tap navigation, timer detection,
/// and an ingredient checklist overlay.
class CookingModeScreen extends StatefulWidget {
  /// Creates cooking mode for the given [recipe].
  const CookingModeScreen({
    required this.recipe,
    super.key,
  });

  /// The recipe to cook.
  final ResolvedRecipe recipe;

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen> {
  late final PageController _pageController;
  int _currentStep = 0;
  final Set<int> _checkedIngredients = <int>{};

  // Timer state
  Timer? _countdownTimer;
  int _timerSecondsRemaining = 0;
  bool _timerRunning = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pageController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step < 0 || step >= widget.recipe.steps.length) return;
    setState(() {
      _currentStep = step;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() => _goToStep(_currentStep + 1);
  void _previousStep() => _goToStep(_currentStep - 1);

  void _startTimer(int minutes) {
    _countdownTimer?.cancel();
    setState(() {
      _timerSecondsRemaining = minutes * 60;
      _timerRunning = true;
    });
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        setState(() {
          _timerSecondsRemaining--;
          if (_timerSecondsRemaining <= 0) {
            _timerRunning = false;
            timer.cancel();
            HapticFeedback.heavyImpact();
          }
        });
      },
    );
  }

  void _cancelTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _timerRunning = false;
      _timerSecondsRemaining = 0;
    });
  }

  String _formatTimerDisplay(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showIngredientChecklist() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (BuildContext context, ScrollController scrollController) {
                return Column(
                  children: <Widget>[
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Ingredients',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: widget.recipe.ingredients.length,
                        itemBuilder: (BuildContext context, int index) {
                          final ResolvedIngredient ingredient =
                              widget.recipe.ingredients[index];
                          final bool isChecked =
                              _checkedIngredients.contains(index);

                          return _IngredientChecklistItem(
                            ingredient: ingredient,
                            isChecked: isChecked,
                            onToggle: () {
                              setState(() {
                                if (isChecked) {
                                  _checkedIngredients.remove(index);
                                } else {
                                  _checkedIngredients.add(index);
                                }
                              });
                              setModalState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<recipe_model.Step> steps = widget.recipe.steps;

    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.recipe.title,
            style: const TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: 'Ingredients',
              onPressed: _showIngredientChecklist,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              // Timer bar
              if (_timerRunning || _timerSecondsRemaining > 0)
                _TimerBar(
                  secondsRemaining: _timerSecondsRemaining,
                  isRunning: _timerRunning,
                  formattedTime: _formatTimerDisplay(_timerSecondsRemaining),
                  onCancel: _cancelTimer,
                ),
              // Progress indicator
              _StepProgressBar(
                currentStep: _currentStep,
                totalSteps: steps.length,
              ),
              // Step content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (int index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  itemCount: steps.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _StepCard(
                      step: steps[index],
                      isTimerRunning: _timerRunning,
                      onStartTimer: _startTimer,
                    );
                  },
                ),
              ),
              // Navigation buttons
              _NavigationBar(
                currentStep: _currentStep,
                totalSteps: steps.length,
                onPrevious: _previousStep,
                onNext: _nextStep,
                onFinish: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Progress bar showing which step the user is on.
class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: <Widget>[
          Text(
            'Step ${currentStep + 1} of $totalSteps',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: totalSteps > 0 ? (currentStep + 1) / totalSteps : 0,
            backgroundColor: Colors.grey.shade800,
            valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.deepOrange),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }
}

/// A single step displayed as a full-screen card.
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.isTimerRunning,
    required this.onStartTimer,
  });

  final recipe_model.Step step;
  final bool isTimerRunning;
  final ValueChanged<int> onStartTimer;

  @override
  Widget build(BuildContext context) {
    final DetectedTimer? timer = detectTimer(step.instruction);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Step number badge
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.deepOrange,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${step.number}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Instruction text (large, readable)
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  step.instruction,
                  style: const TextStyle(
                    fontSize: 24,
                    height: 1.5,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          // Timer button if applicable
          if (timer != null && !isTimerRunning) ...<Widget>[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => onStartTimer(timer.durationMinutes),
              icon: const Icon(Icons.timer),
              label: Text('Start ${timer.label} Timer'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
          // Time hint from recipe data
          if (step.timeMinutes != null && timer == null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                '${step.timeMinutes} min',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Timer bar displayed at the top when a timer is active.
class _TimerBar extends StatelessWidget {
  const _TimerBar({
    required this.secondsRemaining,
    required this.isRunning,
    required this.formattedTime,
    required this.onCancel,
  });

  final int secondsRemaining;
  final bool isRunning;
  final String formattedTime;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final bool isDone = !isRunning && secondsRemaining <= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isDone ? Colors.green.shade700 : Colors.deepOrange.shade700,
      child: Row(
        children: <Widget>[
          Icon(
            isDone ? Icons.check_circle : Icons.timer,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isDone ? 'Timer done!' : formattedTime,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
          TextButton(
            onPressed: onCancel,
            child: const Text(
              'Dismiss',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom navigation bar for stepping through recipe.
class _NavigationBar extends StatelessWidget {
  const _NavigationBar({
    required this.currentStep,
    required this.totalSteps,
    required this.onPrevious,
    required this.onNext,
    required this.onFinish,
  });

  final int currentStep;
  final int totalSteps;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final bool isFirst = currentStep == 0;
    final bool isLast = currentStep >= totalSteps - 1;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isFirst ? null : onPrevious,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: isFirst ? Colors.grey.shade700 : Colors.white,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: isLast
                ? FilledButton.icon(
                    onPressed: onFinish,
                    icon: const Icon(Icons.check),
                    label: const Text('Done'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: onNext,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// A single ingredient in the checklist overlay.
class _IngredientChecklistItem extends StatelessWidget {
  const _IngredientChecklistItem({
    required this.ingredient,
    required this.isChecked,
    required this.onToggle,
  });

  final ResolvedIngredient ingredient;
  final bool isChecked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final ParsedIngredient parsed = ingredient.parsed;

    final StringBuffer display = StringBuffer();
    if (parsed.quantity != null) {
      final double qty = parsed.quantity!;
      if (qty == qty.toInt().toDouble()) {
        display.write(qty.toInt());
      } else {
        display.write(qty);
      }
      display.write(' ');
    }
    if (parsed.unit != null) {
      display.write('${parsed.unit} ');
    }
    display.write(parsed.name);
    if (parsed.preparation != null) {
      display.write(', ${parsed.preparation}');
    }

    return ListTile(
      leading: Checkbox(
        value: isChecked,
        onChanged: (_) => onToggle(),
        activeColor: Colors.deepOrange,
      ),
      title: Text(
        display.toString(),
        style: TextStyle(
          fontSize: 16,
          decoration: isChecked ? TextDecoration.lineThrough : null,
          color: isChecked ? Colors.grey : null,
        ),
      ),
      onTap: onToggle,
    );
  }
}
