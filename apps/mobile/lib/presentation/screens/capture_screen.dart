/// Capture screen for recipes via text, social links, or screenshots.
///
/// Provides three capture modes:
/// 1. Text area for pasting/typing recipe text (manual, synchronous).
/// 2. URL input field for social media links (async with polling).
/// 3. Camera/gallery button for screenshot capture (async with polling).
///
/// Async captures show a progress indicator and navigate to the recipe
/// detail on completion.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/models/recipe.dart';
import '../providers/capture_provider.dart';
import '../providers/recipe_list_provider.dart';

/// Screen for capturing a recipe from text, URL, or screenshot.
///
/// The user can paste recipe text, enter a social media URL, or pick
/// an image from the camera/gallery. Each mode uses the appropriate
/// capture pipeline (sync for text, async for URLs and screenshots).
class CaptureScreen extends ConsumerStatefulWidget {
  /// Creates the capture screen.
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  late final TabController _tabController;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _textController.dispose();
    _urlController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  bool _isUrl(String text) {
    final String trimmed = text.trim().toLowerCase();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  Future<void> _handleTextSubmit() async {
    final String text = _textController.text.trim();
    if (text.isEmpty) {
      return;
    }

    // Auto-detect if the user pasted a URL in the text field
    if (_isUrl(text)) {
      await _handleUrlCapture(text);
      return;
    }

    final CaptureNotifier notifier = ref.read(captureProvider.notifier);
    final ResolvedRecipe? recipe = await notifier.capture(text);

    if (recipe != null && mounted) {
      ref.read(recipeListProvider.notifier).addRecipe(recipe);
      context.go('/recipes/${recipe.id}');
    }
  }

  Future<void> _handleUrlSubmit() async {
    final String url = _urlController.text.trim();
    if (url.isEmpty) {
      return;
    }
    await _handleUrlCapture(url);
  }

  Future<void> _handleUrlCapture(String url) async {
    final CaptureNotifier notifier = ref.read(captureProvider.notifier);
    await notifier.captureSocialLink(url);
    // Polling happens automatically via the notifier
  }

  Future<void> _handleImageCapture(ImageSource source) async {
    final XFile? image = await _imagePicker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );

    if (image == null) {
      return;
    }

    final Uint8List bytes = await image.readAsBytes();
    final String base64Data = base64Encode(bytes);

    final CaptureNotifier notifier = ref.read(captureProvider.notifier);
    await notifier.captureScreenshot(base64Data);
    // Polling happens automatically via the notifier
  }

  @override
  Widget build(BuildContext context) {
    final CaptureState captureState = ref.watch(captureProvider);
    final bool isActive = captureState is CaptureLoading ||
        captureState is CapturePolling;

    // Listen for success and navigate
    ref.listen<CaptureState>(captureProvider, (CaptureState? previous, CaptureState next) {
      if (next case CaptureSuccess(:final ResolvedRecipe recipe)) {
        ref.read(recipeListProvider.notifier).addRecipe(recipe);
        context.go('/recipes/${recipe.id}');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Recipe'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Tab>[
            Tab(icon: Icon(Icons.edit_note), text: 'Text'),
            Tab(icon: Icon(Icons.link), text: 'Link'),
            Tab(icon: Icon(Icons.camera_alt), text: 'Photo'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  _buildTextTab(isActive),
                  _buildUrlTab(isActive),
                  _buildPhotoTab(isActive),
                ],
              ),
            ),
            // Status indicator for async captures
            if (captureState case CapturePolling(:final String pipelineState))
              _buildPollingIndicator(pipelineState),
            if (captureState case CaptureLoading(:final String description))
              _buildLoadingIndicator(description),
            if (captureState case CaptureError(:final String message))
              _buildErrorMessage(message),
          ],
        ),
      ),
    );
  }

  Widget _buildTextTab(bool isActive) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Paste or type your recipe below',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _textController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              enabled: !isActive,
              decoration: const InputDecoration(
                hintText:
                    'e.g. Chocolate Cake\n\nIngredients:\n2 cups flour\n1 cup sugar\n...\n\nInstructions:\n1. Preheat oven to 350F\n...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: isActive ? null : _handleTextSubmit,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Save Recipe'),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlTab(bool isActive) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Paste a recipe URL from social media',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Supports Instagram, TikTok, YouTube, and recipe websites.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            enabled: !isActive,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'https://www.instagram.com/p/...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: isActive ? null : _handleUrlSubmit,
            icon: const Icon(Icons.download),
            label: const Text('Extract Recipe'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoTab(bool isActive) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Take a photo or pick a screenshot',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Capture a recipe from a screenshot, cookbook photo, or handwritten note.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isActive
                      ? null
                      : () => _handleImageCapture(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isActive
                      ? null
                      : () => _handleImageCapture(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPollingIndicator(String pipelineState) {
    final String statusText = switch (pipelineState) {
      'received' => 'Queued for processing...',
      'processing' => 'Extracting recipe...',
      'extracted' => 'Assembling recipe...',
      _ => 'Processing...',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: <Widget>[
          const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: <Widget>[
          const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            onPressed: () => ref.read(captureProvider.notifier).reset(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
