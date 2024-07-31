// ignore_for_file: unused_field

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/features/call/repository/voice_call_repository.dart';
import 'package:hash_balance/models/user_model.dart';

final voiceCallControllerProvider =
    StateNotifierProvider<VoiceCallController, bool>((ref) {
  return VoiceCallController(
    voiceCallRepository: ref.watch(voiceCallRepositoryProvider),
    ref: ref,
  );
});

class VoiceCallController extends StateNotifier<bool> {
  final VoiceCallRepository _voiceCallRepository;

  final Ref _ref;

  VoiceCallController({
    required VoiceCallRepository voiceCallRepository,
    required Ref ref,
  })  : _voiceCallRepository = voiceCallRepository,
        _ref = ref,
        super(false);

  FutureString fetchAgoraToken(String channelName) async {
    try {
      return await _voiceCallRepository.fetchAgoraToken(channelName);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  FutureVoid notifyIncomingCall(UserModel targetUser) async {
    try {
      final userController = _ref.watch(userControllerProvider.notifier);
      final targetUserDeviceToken =
          await userController.getUserDeviceTokens(targetUser.uid);
      await _voiceCallRepository.notifyIncomingCall(targetUserDeviceToken,
          '${targetUser.name} is calling....', targetUser.name);
      return right(null);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }
}
