import 'dart:io';
import 'package:dio/dio.dart';

import '../utils/logger.dart';

// Abstract AI Provider Interface
abstract class AIProvider {
  Future<AIGenerationResult> generateImage({
    required String prompt,
    required int width,
    required int height,
    String? stylePreset,
    Map<String, dynamic>? additionalParams,
  });

  Future<AIGenerationStatus> checkStatus(String jobId);
}

// AI Generation Result
class AIGenerationResult {
  final String jobId;
  final String? imageUrl;
  final AIGenerationStatus status;
  final String? error;

  AIGenerationResult({
    required this.jobId,
    this.imageUrl,
    required this.status,
    this.error,
  });
}

// AI Generation Status
enum AIGenerationStatus {
  queued,
  processing,
  succeeded,
  failed,
}

// Stability AI Provider Implementation
class StabilityAIProvider implements AIProvider {
  final String apiKey;
  final Dio _dio;

  static const String baseUrl = 'https://api.stability.ai/v1';

  StabilityAIProvider({required this.apiKey})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ));

  @override
  Future<AIGenerationResult> generateImage({
    required String prompt,
    required int width,
    required int height,
    String? stylePreset,
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      final response = await _dio.post(
        '/generation/stable-diffusion-xl-1024-v1-0/text-to-image',
        data: {
          'text_prompts': [
            {'text': prompt, 'weight': 1}
          ],
          'cfg_scale': 7,
          'width': width,
          'height': height,
          'samples': 1,
          'steps': 30,
          if (stylePreset != null) 'style_preset': stylePreset,
          ...?additionalParams,
        },
      );

      if (response.statusCode == 200) {
        final artifacts = response.data['artifacts'] as List;
        if (artifacts.isNotEmpty) {
          final base64Image = artifacts[0]['base64'] as String;

          return AIGenerationResult(
            jobId: DateTime.now().millisecondsSinceEpoch.toString(),
            imageUrl: 'data:image/png;base64,$base64Image',
            status: AIGenerationStatus.succeeded,
          );
        }
      }

      throw Exception('No image generated');
    } catch (e) {
      AppLogger.error('Stability AI generation error', error: e);
      return AIGenerationResult(
        jobId: DateTime.now().millisecondsSinceEpoch.toString(),
        status: AIGenerationStatus.failed,
        error: e.toString(),
      );
    }
  }

  @override
  Future<AIGenerationStatus> checkStatus(String jobId) async {
    // Stability AI returns results immediately, so this is not needed
    return AIGenerationStatus.succeeded;
  }
}

// OpenAI DALL-E Provider Implementation
class OpenAIProvider implements AIProvider {
  final String apiKey;
  final Dio _dio;

  static const String baseUrl = 'https://api.openai.com/v1';

  OpenAIProvider({required this.apiKey})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ));

  @override
  Future<AIGenerationResult> generateImage({
    required String prompt,
    required int width,
    required int height,
    String? stylePreset,
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      // DALL-E 3 only supports specific sizes
      String size = '1024x1024';
      if (width == 1024 && height == 1792) {
        size = '1024x1792';
      } else if (width == 1792 && height == 1024) {
        size = '1792x1024';
      }

      final response = await _dio.post(
        '/images/generations',
        data: {
          'model': 'dall-e-3',
          'prompt': prompt,
          'n': 1,
          'size': size,
          'quality': 'hd',
          ...?additionalParams,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        if (data.isNotEmpty) {
          final imageUrl = data[0]['url'] as String;

          return AIGenerationResult(
            jobId: DateTime.now().millisecondsSinceEpoch.toString(),
            imageUrl: imageUrl,
            status: AIGenerationStatus.succeeded,
          );
        }
      }

      throw Exception('No image generated');
    } catch (e) {
      AppLogger.error('OpenAI generation error', error: e);
      return AIGenerationResult(
        jobId: DateTime.now().millisecondsSinceEpoch.toString(),
        status: AIGenerationStatus.failed,
        error: e.toString(),
      );
    }
  }

  @override
  Future<AIGenerationStatus> checkStatus(String jobId) async {
    // OpenAI DALL-E returns results immediately
    return AIGenerationStatus.succeeded;
  }
}

// Factory to get AI provider based on environment
class AIProviderFactory {
  static AIProvider getProvider({
    required String providerType,
    required String apiKey,
  }) {
    switch (providerType.toLowerCase()) {
      case 'stability':
        return StabilityAIProvider(apiKey: apiKey);
      case 'openai':
        return OpenAIProvider(apiKey: apiKey);
      default:
        throw Exception('Unknown AI provider: $providerType');
    }
  }
}
