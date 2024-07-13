// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final pushNotificationRepositoryProvider = Provider((ref) {
  return PushNotificationRepository();
});

class PushNotificationRepository {
  PushNotificationRepository();

  Future<void> sendPushNotificationFriendRequest(
    List<String> deviceIds,
    String uid,
  ) async {
    const String oneSignalAppId = 'b10fa7dd-5d27-4634-9409-11169c4425e1';
    const String oneSignalRestApiKey =
        'MDJiZTY5ZTAtYmRiZC00N2I4LWE1MjUtYjQzODA4MTMwMTk2';
    final response = await http.post(
      Uri.parse('https://api.onesignal.com/notifications'),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Basic $oneSignalRestApiKey',
      },
      body: jsonEncode({
        'app_id': oneSignalAppId,
        'include_aliases': {uid: deviceIds},
        'target_channel': 'push',
        'headings': {'en': 'Notification Title'},
        'contents': {'en': 'This is a test message'},
      }),
    );
    if (response.statusCode == 200) {
      print('SUCCESSFULLY SENT API');
    }
  }
}
