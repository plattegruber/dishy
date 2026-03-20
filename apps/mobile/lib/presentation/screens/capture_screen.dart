/// Tabbed capture screen for Text, Link, and Photo input modalities.
///
/// Provides three tabs:
/// - **Text**: paste or type recipe text (synchronous capture)
/// - **Link**: paste a social media or recipe URL (async via queue)
/// - **Photo**: take or select a screenshot (async via queue)
///
/// Async captures show a polling indicator until the recipe is ready.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/models/recipe.dart';
import '../providers/capture_provider.dart';
import '../providers/recipe_list_provider.dart';

/// Screen for capturing a recipe from multiple input modalities.
///
/// Uses a [TabBar] with three tabs: Text, Link, Photo. Each tab
/// provides the appropriate input UI and submits through the
/// capture provider.
class CaptureScreen extends ConsumerStatefulWidget {
  /// Creates the capture screen.
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _onCaptureSuccess(ResolvedRecipe recipe) {
    if (!mounted) return;
    ref.read(recipeListProvider.notifier).addRecipe(recipe);
    context.go('/recipes/${recipe.id}');
  }

  Future<void> _handleTextSubmit() async {
    final String text = _textController.text.trim();
    if (text.isEmpty) return;

    final CaptureNotifier notifier = ref.read(captureProvider.notifier);
    final ResolvedRecipe? recipe = await notifier.capture(text);

    if (recipe != null) {
      _onCaptureSuccess(recipe);
    }
  }

  Future<void> _handleLinkSubmit() async {
    final String url = _urlController.text.trim();
    if (url.isEmpty) return;

    final CaptureNotifier notifier = ref.read(captureProvider.notifier);
    await notifier.captureSocialLink(url);
    // Polling handles the rest via state changes
  }

  Future<void> _handlePhotoCapture(ImageSource source) async {
    final XFile? image = await _imagePicker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    if (image == null) return;

    final List<int> bytes = await image.readAsBytes();
    final String base64Image = base64Encode(bytes);

    // Determine content type from file extension
    final String ext = image.path.split('.').last.toLowerCase();
    final String contentType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final CaptureNotifier notifier = ref.read(captureProvider.notifier);
    await notifier.captureScreenshot(
      imageBase64: base64Image,
      contentType: contentType,
    );
    // Polling handles the rest via state changes
  }

  @override
  Widget build(BuildContext context) {
    final CaptureState captureState = ref.watch(captureProvider);

    // Listen for success state and navigate
    ref.listen<CaptureState>(captureProvider, (CaptureState? prev, CaptureState next) {
      if (next is CaptureSuccess) {
        _onCaptureSuccess(next.recipe);
      }
    });

    final bool isActive = captureState is CaptureLoading ||
        captureState is CapturePolling;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Recipe'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(icon: Icon(Icons.text_fields), text: 'Text'),
            Tab(icon: Icon(Icons.link), text: 'Link'),
            Tab(icon: Icon(Icons.photo_camera), text: 'Photo'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Status bar for async captures
            if (captureState is CapturePolling)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  children: <Widget>[
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Processing capture... (${captureState.status})',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (captureState case CaptureError(:final String message))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Theme.of(context).colorScheme.errorContainer,
                child: Text(
                  message,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  _buildTextTab(isActive),
                  _buildLinkTab(isActive),
                  _buildPhotoTab(isActive),
                ],
              ),
            ),
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
            icon: isActive
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_fix_high),
            label: Text(isActive ? 'Extracting...' : 'Save Recipe'),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTab(bool isActive) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Paste a recipe link',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Works with Instagram, TikTok, YouTube, and recipe websites.',
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
            onPressed: isActive ? null : _handleLinkSubmit,
            icon: isActive
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download),
            label: Text(isActive ? 'Processing...' : 'Capture from Link'),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'Capture from a photo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Take a photo or select a screenshot of a recipe.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed:
                isActive ? null : () => _handlePhotoCapture(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take Photo'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: isActive
                ? null
                : () => _handlePhotoCapture(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Choose from Gallery'),
          ),
          if (isActive) ...<Widget>[
            const SizedBox(height: 24),
            const Center(
              child: Column(
                children: <Widget>[
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Processing image...'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
