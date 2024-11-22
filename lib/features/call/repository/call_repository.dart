import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/models/call_model.dart';
import 'package:hash_balance/models/conbined_models/call_data_model.dart';
import 'package:hash_balance/models/user_model.dart';
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
  //REFERENCE ALL THE USERS
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);

  //FETCH AGORA TOKEN
  Future<Either<Failures, String>> fetchAgoraToken(String channelName) async {
    try {
      final response = await http.get(Uri.parse(
          '${Constants.domain}/agoraAccessToken?channelName=$channelName'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return right(data['token']);
      } else if (response.statusCode == 400) {
        throw Exception(
            'Bad Request: The server could not understand the request. Check if the channel name is provided correctly.');
      } else if (response.statusCode == 500) {
        throw Exception(
            'Server Error: Something went wrong on the server while generating the token.');
      } else {
        throw Exception('${response.statusCode}');
      }
    } catch (e) {
      return left(Failures('Error fetching Agora token: ${e.toString()}'));
    }
  }

  Future<Either<Failures, void>> initCall(Call call) async {
    try {
      await _calls.doc(call.id).set(call.toMap());
      return right(null);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, void>> acceptCall(Call call) async {
    try {
      await _calls.doc(call.id).update({
        'status': Constants.callStatusOngoing,
        'agoraToken': call.agoraToken,
      });
      return right(null);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, void>> endCall(Call call) async {
    try {
      await _calls.doc(call.id).update({'status': Constants.callStatusEnded});
      return right(null);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, void>> cancelCall(Call call) async {
    try {
      await _calls.doc(call.id).update({'status': Constants.callStatusMissed});
      return right(null);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, void>> declineCall(Call call) async {
    try {
      await _calls
          .doc(call.id)
          .update({'status': Constants.callStatusDeclined});
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
      return right(callDataModel);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<CallDataModel?> listenToIncomingCalls(UserModel currentUser) {
    return _calls
        .where('receiverUid', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: Constants.callStatusDialling)
        .snapshots()
        .asyncMap(
      (snapshot) async {
        if (snapshot.docs.isNotEmpty) {
          final callDoc = snapshot.docs.firstOrNull;
          if (callDoc != null) {
            final call = Call.fromMap(callDoc.data() as Map<String, dynamic>);
            final callerDoc = await _users.doc(call.callerUid).get();
            final caller =
                UserModel.fromMap(callerDoc.data() as Map<String, dynamic>);
            final callData = CallDataModel(
              call: call,
              caller: caller,
              receiver: currentUser,
            );
            return callData;
          } else {
            return null;
          }
        } else {
          return null;
        }
      },
    );
  }

  Stream<Call?> listenToCall(String callId) {
    return _calls.doc(callId).snapshots().map((snapshot) {
      return Call.fromMap(snapshot.data() as Map<String, dynamic>);
    });
  }
}
