// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:http/http.dart' as http;

final pushNotificationRepositoryProvider = Provider((ref) {
  return PushNotificationRepository();
});

class PushNotificationRepository {
  PushNotificationRepository();

  Future<void> sendFCMNotification(
    String token,
    String message,
    String title,
    Map<String, dynamic> data,
  ) async {
    print('TOKENS TO BE SENT: $token');
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
      }),
    );
    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Failed to send notification');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  }
}
