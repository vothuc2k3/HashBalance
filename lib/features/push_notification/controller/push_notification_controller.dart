// ignore_for_file: unused_field

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/push_notification/repository/push_notification_repository.dart';

final pushNotificationControllerProvider =
    StateNotifierProvider<PushNotificationController, bool>(
  (ref) => PushNotificationController(
      authController: ref.read(authControllerProvider.notifier),
      pushNotificationRepository: ref.read(pushNotificationRepositoryProvider),
      ref: ref),
);

class PushNotificationController extends StateNotifier<bool> {
  final AuthController _authController;
  final PushNotificationRepository _pushNotificationRepository;
  final Ref _ref;

  PushNotificationController({
    required AuthController authController,
    required PushNotificationRepository pushNotificationRepository,
    required Ref ref,
  })  : _authController = authController,
        _pushNotificationRepository = pushNotificationRepository,
        _ref = ref,
        super(false);

  Future<void> sendPushNotificationFriendRequest(
    List<String> deviceIds,
    String targetUid,
  ) async {
    await _pushNotificationRepository.sendPushNotificationFriendRequest(
      deviceIds,
      targetUid,
    );
  }
}
