import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final cloudVisionRepositoryProvider = Provider((ref) {
  return CloudVisionRepository();
});

class CloudVisionRepository {
  CloudVisionRepository();

  Future<Either<Failures, bool>> areImagesSafe(
      List<String> base64Images) async {
    final url = "${dotenv.env['DOMAIN']}/analyzeImage";
    for (final base64Image in base64Images) {
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"base64Image": base64Image}),
        );

        if (response.statusCode != 200) {
          return left(Failures(
              "Failed to analyze image. Status code: ${response.statusCode}"));
        }

        final result = jsonDecode(response.body);
        if (result['isSafe'] == false) {
          return right(false);
        }
      } catch (e) {
        Logger().e("Error analyzing image: $e");
        return left(Failures("Error analyzing images: $e"));
      }
    }

    return right(true);
  }
}
