// ignore_for_file: unused_field, avoid_print

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/core/providers/onesignal_provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;

final pushNotificationRepositoryProvider = Provider((ref) {
  return PushNotificationRepository(
      oneSignalNotification: ref.watch(oneSignalNotificationsProvider));
});

class PushNotificationRepository {
  final OneSignalNotifications _oneSignalNotifications;

  PushNotificationRepository({
    required OneSignalNotifications oneSignalNotification,
  }) : _oneSignalNotifications = oneSignalNotification;

  void sendPushNotification() async {
    const String oneSignalAppId = '2c3828a5-d158-4947-988e-3f20d00111d1';
    const String oneSignalRestApiKey =
        'ZmQ5NWNhNDUtNTVkMS00ZmI1LTk4YjgtMDg4NWMxYTkyMzdi';
    final externalId = await OneSignal.User.getExternalId();
    final response = await http.post(
      Uri.parse('https://api.onesignal.com/notifications'),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Basic $oneSignalRestApiKey',
      },
      body: jsonEncode({
        'app_id': oneSignalAppId,
        'include_aliases': {
          'external_id': [externalId]
        },
        'target_channel': 'push',
        'headings': {'en': 'Notification Title'},
        'contents': {'en': 'This is a test message'},
      }),
    );
    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Failed to send notification: ${response.body}');
    }
  }
}
