// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/call_model.dart';
import 'package:http/http.dart' as http;

final callRepositoryProvider = Provider((ref) {
  return CallRepository(firestore: ref.read(firebaseFirestoreProvider));
});

class CallRepository {
  CallRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  //REFERENCE ALL THE USERS
  CollectionReference get _calls =>
      _firestore.collection(FirebaseConstants.callCollection);

  //FETCH AGORA TOKEN
  FutureString fetchAgoraToken(String channelName) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.domain}/access_token?channelName=$channelName'),
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

  Future<void> notifyIncomingCall(
      String token, String message, String callerName) async {
    final url = Uri.parse('${Constants.domain}/sendPushNotification');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'token': token,
        'message': message,
        'title': 'Incoming Call',
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

  FutureVoid initCall(Call call) async {
    try {
      await _calls.doc(call.id).set(call.toMap());
      return right(null);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  FutureVoid joinCall(Call call) async {
    try {
      await _calls.doc(call.id).update({'status': Constants.callStatusOngoing});
      return right(null);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  FutureVoid endCall(Call call) async {
    try {
      await _calls.doc(call.id).update({'status': Constants.callStatusEnded});
      return right(null);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }


}
