// ignore_for_file: unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/features/call/repository/call_repository.dart';
import 'package:hash_balance/models/call_model.dart';
import 'package:hash_balance/models/conbined_models/call_data_model.dart';
import 'package:hash_balance/models/user_model.dart';

final listenToCallProvider = StreamProvider.family((ref, String callId) {
  final callController = ref.read(callControllerProvider.notifier);
  return callController.listenToCall(callId);
});

final listenToIncomingCallsProvider = StreamProvider<CallDataModel?>(
  (ref) {
    final callController = ref.read(callControllerProvider.notifier);
    return callController.listenToIncomingCalls();
  },
);

final callControllerProvider = StateNotifierProvider((ref) {
  return CallController(
    callRepository: ref.read(callRepositoryProvider),
    ref: ref,
  );
});

class CallController extends StateNotifier<CallDataModel?> {
  final CallRepository _callRepository;

  final Ref _ref;

  CallController({
    required CallRepository callRepository,
    required Ref ref,
  })  : _callRepository = callRepository,
        _ref = ref,
        super(null);

  FutureString _fetchAgoraToken(String channelName) async {
    try {
      return await _callRepository.fetchAgoraToken(channelName);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  FutureVoid _notifyIncomingCall(UserModel targetUser) async {
    try {
      final userController = _ref.read(userControllerProvider.notifier);
      final targetUserDeviceToken =
          await userController.getUserDeviceTokens(targetUser.uid);
      await _callRepository.notifyIncomingCall(targetUserDeviceToken,
          '${targetUser.name} is calling....', targetUser.name);
      return right(null);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, Call>> initCall(UserModel targetUser) async {
    try {
      final currentUser = _ref.read(userProvider)!;
      final callModel = Call(
        id: await generateRandomId(),
        callerUid: currentUser.uid,
        receiverUid: targetUser.uid,
        status: Constants.callStatusDialling,
        createdAt: Timestamp.now(),
      );
      final result = await _callRepository.initCall(callModel);
      return result.fold(
        (l) {
          return left(l);
        },
        (r) {
          return right(callModel);
        },
      );
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  FutureVoid joinCall(Call call) async {
    try {
      final uids = getUids(call.callerUid, call.receiverUid);
      final result = await _fetchAgoraToken(uids);
      return result.fold((l) => left(l), (agoraToken) async {
        final callCopy = call.copyWith(agoraToken: agoraToken);
        await _callRepository.joinCall(callCopy);
        return right(null);
      });
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  FutureVoid cancelCall(Call call) async {
    try {
      return await _callRepository.cancelCall(call);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  FutureVoid declineCall(Call call) async {
    try {
      return await _callRepository.declineCall(call);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, CallDataModel>> fetchCallData(Call call) async {
    try {
      return await _callRepository.fetchCallData(call);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<CallDataModel?> listenToIncomingCalls() {
    final currentUser = _ref.read(userProvider)!;
    return _callRepository.listenToIncomingCalls(currentUser);
  }

  Stream<Call?> listenToCall(String callId) {
    return _callRepository.listenToCall(callId);
  }
}
