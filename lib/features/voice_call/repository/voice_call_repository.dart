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
      final response = await http.get(Uri.parse(
          'http://26.151.104.63:3000/access_token?channelName=$channelName'));
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
}
