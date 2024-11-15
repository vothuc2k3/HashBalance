import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

final pushNotificationRepositoryProvider = Provider((ref) {
  return PushNotificationRepository();
});

class PushNotificationRepository {
  PushNotificationRepository();

  final _logger = Logger();

  Future<void> sendFCMNotification(
    String token,
    String message,
    String title,
    Map<String, dynamic> data,
    String type,
  ) async {
    _logger.d('TOKENS TO BE SENT: $token');
    final url = Uri.parse('${Constants.domain}/sendPushNotification');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'tokens': [token],
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
