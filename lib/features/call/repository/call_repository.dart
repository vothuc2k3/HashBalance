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
import 'package:hash_balance/models/conbined_models/call_data_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

final callRepositoryProvider = Provider((ref) {
  return CallRepository(firestore: ref.read(firebaseFirestoreProvider));
});

class CallRepository {
  CallRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;
  final Logger _logger = Logger();

  //REFERENCE ALL THE USERS
  CollectionReference get _calls =>
      _firestore.collection(FirebaseConstants.callCollection);
  //REFERENCE ALL THE USERS
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);

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
      ('Notification sent successfully');
    } else {
      _logger.d('Failed to send notification');
      _logger.d('Response status: ${response.statusCode}');
      _logger.d('Response body: ${response.body}');
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

  Future<Either<Failures, CallDataModel>> fetchCallData(Call call) async {
    try {
      final callerDoc = await _users.doc(call.callerUid).get();
      final caller =
          UserModel.fromMap(callerDoc.data() as Map<String, dynamic>);
      final receiverDoc = await _users.doc(call.receiverUid).get();
      final receiver =
          UserModel.fromMap(receiverDoc.data() as Map<String, dynamic>);
      final callDataModel =
          CallDataModel(call: call, caller: caller, receiver: receiver);
      _logger.d(callDataModel.toString());
      return right(callDataModel);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }
}
