// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:http/http.dart' as http;

final pushNotificationRepositoryProvider = Provider((ref) {
  return PushNotificationRepository();
});

class PushNotificationRepository {
  PushNotificationRepository();

  Future<void> sendFCMNotification(
      List<String> tokens, String message, String title) async {
    final url = Uri.parse('http://${Constants.ip}:3000/sendPushNotification');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'tokens': tokens,
        'message': message,
        'title': title,
      }),
    );
    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Failed to send notification');
    }
  }
}
