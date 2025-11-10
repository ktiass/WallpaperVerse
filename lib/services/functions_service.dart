import 'package:cloud_functions/cloud_functions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../utils/logger.dart';

part 'functions_service.g.dart';

class FunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Validate receipt and grant credits
  Future<Map<String, dynamic>> validateReceipt({
    required String raw,
    required String platform,
  }) async {
    try {
      final result = await _functions.httpsCallable('validateReceipt').call({
        'raw': raw,
        'platform': platform,
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Validate receipt error', error: e);
      rethrow;
    }
  }

  // Spend credits
  Future<Map<String, dynamic>> spendCredits({
    required int amount,
    required String reason,
    String? refId,
  }) async {
    try {
      final result = await _functions.httpsCallable('spendCredits').call({
        'amount': amount,
        'reason': reason,
        if (refId != null) 'refId': refId,
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Spend credits error', error: e);
      rethrow;
    }
  }

  // Request AI generation
  Future<String> requestGeneration({
    required String prompt,
    required String aspect,
    String? stylePreset,
    double? chromatic,
  }) async {
    try {
      final result = await _functions.httpsCallable('requestGeneration').call({
        'prompt': prompt,
        'aspect': aspect,
        if (stylePreset != null) 'stylePreset': stylePreset,
        if (chromatic != null) 'chromatic': chromatic,
      });

      final data = result.data as Map<String, dynamic>;
      return data['genId'] as String;
    } catch (e) {
      AppLogger.error('Request generation error', error: e);
      rethrow;
    }
  }

  // Unlock generated wallpaper
  Future<bool> unlockGenerated(String genId) async {
    try {
      final result = await _functions.httpsCallable('unlockGenerated').call({
        'genId': genId,
      });

      final data = result.data as Map<String, dynamic>;
      return data['owned'] as bool;
    } catch (e) {
      AppLogger.error('Unlock generated error', error: e);
      rethrow;
    }
  }

  // Purchase wallpaper
  Future<bool> purchaseWallpaper(String wallpaperId) async {
    try {
      final result = await _functions.httpsCallable('purchaseWallpaper').call({
        'wallpaperId': wallpaperId,
      });

      final data = result.data as Map<String, dynamic>;
      return data['owned'] as bool;
    } catch (e) {
      AppLogger.error('Purchase wallpaper error', error: e);
      rethrow;
    }
  }
}

@riverpod
FunctionsService functionsService(FunctionsServiceRef ref) {
  return FunctionsService();
}
