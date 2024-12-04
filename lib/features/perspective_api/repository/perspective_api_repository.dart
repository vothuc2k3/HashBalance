import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final perspectiveApiRepositoryProvider = Provider((ref) {
  return PerspectiveApiRepository();
});

class PerspectiveApiRepository {
  PerspectiveApiRepository();

  Future<Either<Failures, String?>> isCommentSafe(String comment) async {
    final url = "${dotenv.env['DOMAIN']}/detectToxicity";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"text": comment}),
      );

      Logger().d("Response status code: ${response.statusCode}");
      Logger().d("Response body: ${response.body}");

      if (response.statusCode != 200) {
        return left(Failures(
            "${response.statusCode}"));
      }

      final result = jsonDecode(response.body);
      final toxicityResult = result['result'];

      if (toxicityResult == null) {
        return left(Failures('Failed to retrieve toxicity analysis result.'));
      }

      final isToxic = toxicityResult['isToxic'] ?? false;

      if (isToxic) {
        final highestAttribute =
            toxicityResult['highestAttribute'] ?? 'UNKNOWN';
        final highestScore = toxicityResult['highestScore'] ?? 0.0;

        final errorMessage = _getErrorMessage(highestAttribute, highestScore);
        return right(errorMessage);
      }

      return right(null);
    } catch (e) {
      Logger().d("Error analyzing comment: $e");
      return left(Failures("Error analyzing comment: $e"));
    }
  }

  String _getErrorMessage(String attribute, double score) {
    switch (attribute) {
      case "TOXICITY":
        return "Your content contains toxic language.";
      case "SEVERE_TOXICITY":
        return "Your content contains severe toxicity.";
      case "INSULT":
        return "Your content contains insulting language.";
      case "PROFANITY":
        return "Your content contains profane language.";
      case "THREAT":
        return "Your content contains threatening language.";
      default:
        return "Your content contains inappropriate content.";
    }
  }
}
