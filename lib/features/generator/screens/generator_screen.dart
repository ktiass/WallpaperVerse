import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/constants.dart';
import '../../../services/functions_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/credit_badge.dart';
import '../../../widgets/loading_overlay.dart';
import '../../../models/generation_model.dart';

class GeneratorScreen extends ConsumerStatefulWidget {
  const GeneratorScreen({super.key});

  @override
  ConsumerState<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends ConsumerState<GeneratorScreen> {
  final _promptController = TextEditingController();
  String _selectedAspect = '9:16';
  String _selectedStyle = 'realistic';
  double _chromatic = 1.0;
  bool _isGenerating = false;
  String? _generationId;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  int _calculateCreditCost() {
    final dimensions = AppConstants.aspectRatios[_selectedAspect]!;
    final pixels = dimensions['width']! * dimensions['height']!;

    if (pixels <= 1024 * 1024) return 1;
    if (pixels <= 1024 * 2048) return 2;
    return 3;
  }

  Future<void> _generate() async {
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a prompt'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    if (_promptController.text.trim().length < AppConstants.minPromptLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prompt is too short'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    final credits = ref.read(userCreditsProvider);
    final cost = _calculateCreditCost();

    if (credits < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient credits'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final functionsService = ref.read(functionsServiceProvider);
      final genId = await functionsService.requestGeneration(
        prompt: _promptController.text.trim(),
        aspect: _selectedAspect,
        stylePreset: _selectedStyle,
        chromatic: _chromatic,
      );

      setState(() => _generationId = genId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Generation started! Check your library.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final credits = ref.watch(userCreditsProvider);
    final creditCost = _calculateCreditCost();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Generator'),
        actions: [
          CreditBadge(
            onTap: () {},
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Prompt input
                TextFormField(
                  controller: _promptController,
                  decoration: InputDecoration(
                    labelText: 'Describe your wallpaper',
                    hintText: 'A beautiful sunset over mountains...',
                    counterText: '${_promptController.text.length}/${AppConstants.maxPromptLength}',
                  ),
                  maxLines: 4,
                  maxLength: AppConstants.maxPromptLength,
                ),
                const SizedBox(height: 24),

                // Aspect ratio selector
                Text(
                  'Aspect Ratio',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: AppConstants.aspectRatios.keys.map((aspect) {
                    final isSelected = _selectedAspect == aspect;
                    return ChoiceChip(
                      label: Text(aspect),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedAspect = aspect);
                      },
                      selectedColor: AppTheme.primaryColor,
                      backgroundColor: AppTheme.cardColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Style preset
                Text(
                  'Style',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: ['realistic', 'artistic', 'anime', 'digital-art'].map((style) {
                    final isSelected = _selectedStyle == style;
                    return ChoiceChip(
                      label: Text(style),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedStyle = style);
                      },
                      selectedColor: AppTheme.primaryColor,
                      backgroundColor: AppTheme.cardColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Chromatic slider
                Text(
                  'Color Intensity: ${_chromatic.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Slider(
                  value: _chromatic,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: _chromatic.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() => _chromatic = value);
                  },
                  activeColor: AppTheme.primaryColor,
                ),
                const SizedBox(height: 32),

                // Credit cost and generate button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: AppTheme.accentColor),
                      const SizedBox(width: 8),
                      Text(
                        'Cost: $creditCost credits',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      Text(
                        'Available: $credits',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isGenerating || credits < creditCost
                      ? null
                      : _generate,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome),
                        const SizedBox(width: 8),
                        Text(_isGenerating ? 'Generating...' : 'Generate'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isGenerating) const LoadingOverlay(message: 'Generating your wallpaper...'),
        ],
      ),
    );
  }
}
