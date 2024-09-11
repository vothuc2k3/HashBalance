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
import 'package:hash_balance/models/user_model.dart';

final callControllerProvider =
    StateNotifierProvider<CallController, bool>((ref) {
  return CallController(
    callRepository: ref.watch(callRepositoryProvider),
    ref: ref,
  );
});

class CallController extends StateNotifier<bool> {
  final CallRepository _callRepository;

  final Ref _ref;

  CallController({
    required CallRepository callRepository,
    required Ref ref,
  })  : _callRepository = callRepository,
        _ref = ref,
        super(false);

  FutureString fetchAgoraToken(String channelName) async {
    try {
      return await _callRepository.fetchAgoraToken(channelName);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  FutureVoid notifyIncomingCall(UserModel targetUser) async {
    try {
      final userController = _ref.watch(userControllerProvider.notifier);
      final targetUserDeviceToken =
          await userController.getUserDeviceTokens(targetUser.uid);
      await _callRepository.notifyIncomingCall(targetUserDeviceToken,
          '${targetUser.name} is calling....', targetUser.name);
      return right(null);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  FutureVoid initCall(UserModel targetUser) async {
    try {
      final currentUser = _ref.watch(userProvider)!;
      final callModel = Call(
        id: await generateRandomId(),
        callerUid: currentUser.uid,
        receiverUid: targetUser.uid,
        status: Constants.callStatusDialling,
        createdAt: Timestamp.now(),
      );
      await _callRepository.initCall(callModel);
      return right(null);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }
}
