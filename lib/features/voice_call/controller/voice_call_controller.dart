// ignore_for_file: unused_field

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/features/voice_call/repository/voice_call_repository.dart';

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

  FutureVoid notifyIncomingCall(String userDeviceToken) async {
    try {
      await _voiceCallRepository.sendFCMNotification(
        userDeviceToken,
        'Nguyen Thi Tu Trinhhhhh',
      );
      return right(null);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }
}
