import 'package:flutter/services.dart';

class ImageEmbeddingBridge {
  static const MethodChannel _channel =
      MethodChannel('com.example.coleccionista/image_embedder');

  Future<List<Map<String, dynamic>>> findMatches({
    required String queryImagePath,
    required List<Map<String, dynamic>> candidates,
    double minScore = 0.80,
    int limit = 5,
  }) async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'findMatches',
      {
        'queryImagePath': queryImagePath,
        'candidates': candidates,
        'minScore': minScore,
        'limit': limit,
      },
    );

    if (result == null) return [];

    return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
