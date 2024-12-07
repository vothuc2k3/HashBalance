import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
final pushNotificationRepositoryProvider = Provider((ref) {
  return PushNotificationRepository();
});

class PushNotificationRepository {
  PushNotificationRepository();

  final _logger = Logger();

  Future<void> sendFCMNotification(
    List<String> tokens,
    String message,
    String title,
    Map<String, String> data,
    String type,
  ) async {
    final url = Uri.parse('${dotenv.env['DOMAIN']}/sendPushNotification');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'tokens': tokens,
        'message': message,
        'title': title,
        'data': data,
        'type': type,
      }),
    );
    if (response.statusCode == 200) {
      _logger.d('Notification sent successfully');
      _logger.d('Response body: ${response.body}');
    } else {
      _logger.d('Failed to send notification');
      _logger.d('Response status: ${response.statusCode}');
      _logger.d('Response body: ${response.body}');
    }
  }
}
