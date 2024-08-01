// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final pushNotificationRepositoryProvider = Provider((ref) {
  return PushNotificationRepository();
});

class PushNotificationRepository {
  PushNotificationRepository();

  Future<void> sendFCMNotification(
    List<String> tokens,
    String message,
    String title,
    Map<String, dynamic> data,
  ) async {
    print('TOKENS TO BE SENT: $tokens');
    final url = Uri.parse(
        'https://hash-balance-backend-6cdfcc4bcae7.herokuapp.com/sendPushNotification');
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
