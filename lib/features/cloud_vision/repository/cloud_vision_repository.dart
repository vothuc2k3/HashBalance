import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hash_balance/core/constants/constants.dart';
import 'package:logger/logger.dart';

final cloudVisionRepositoryProvider = Provider((ref) {
  return CloudVisionRepository();
});

class CloudVisionRepository {
  CloudVisionRepository();

  Future<Either<Failures, bool>> areImagesSafe(
      List<String> base64Images) async {
    final url =
        "https://vision.googleapis.com/v1/images:annotate?key=${Constants.cloudVisionApiKey}";

    final requests = base64Images.map((base64Image) {
      return {
        "image": {"content": base64Image},
        "features": [
          {"type": "SAFE_SEARCH_DETECTION"}
        ]
      };
    }).toList();

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"requests": requests}),
      );

      if (response.statusCode != 200) {
        return left(Failures(
            "Failed to analyze images. Status code: ${response.statusCode}"));
      }

      final result = jsonDecode(response.body);
      Logger().d("Image analysis result: $result");

      for (var i = 0; i < base64Images.length; i++) {
        final safeSearch = result['responses'][i]?['safeSearchAnnotation'];
        if (safeSearch != null) {
          final adultResult = safeSearch['adult'] ?? 'UNKNOWN';
          final violenceResult = safeSearch['violence'] ?? 'UNKNOWN';
          final racyResult = safeSearch['racy'] ?? 'UNKNOWN';
          final medicalResult = safeSearch['medical'] ?? 'UNKNOWN';
          final spoofResult = safeSearch['spoof'] ?? 'UNKNOWN';

          if (!_isSafe(adultResult) ||
              !_isSafe(violenceResult) ||
              !_isSafe(racyResult) ||
              !_isSafe(medicalResult) ||
              !_isSafe(spoofResult)) {
            Logger().d(
              "Image $i failed safety check. Criteria: {"
              "adult: $adultResult, violence: $violenceResult, racy: $racyResult, "
              "medical: $medicalResult, spoof: $spoofResult}",
            );
            return right(false);
          }
        } else {
          Logger().d("Image $i has no safeSearchAnnotation.");
          return right(false);
        }
      }

      Logger().d("All images passed safety check.");
      return right(true);
    } catch (e) {
      Logger().d("Error during image safety analysis: $e");
      return left(Failures("Error during image safety analysis: $e"));
    }
  }

  bool _isSafe(String likelihood) {
    return likelihood == 'VERY_UNLIKELY' || likelihood == 'UNLIKELY';
  }
}
