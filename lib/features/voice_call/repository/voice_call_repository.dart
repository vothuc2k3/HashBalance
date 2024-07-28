import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:http/http.dart' as http;

final voiceCallRepositoryProvider = Provider((ref) {
  return VoiceCallRepository();
});

class VoiceCallRepository {
  //FETCH AGORA TOKEN
  FutureString fetchAgoraToken(String channelName) async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://192.168.8.108:3000/access_token?channelName=$channelName'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return right(data['token']);
      } else {
        throw Exception('Failed to load token');
      }
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<void> sendFCMNotification(String token, String message) async {
    final url =
        Uri.parse('http://192.168.8.108:3000/sendPushNotification');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'token': token,
        'message': message,
      }),
    );

    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Failed to send notification');
    }
  }
}
