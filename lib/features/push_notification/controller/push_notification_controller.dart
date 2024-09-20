import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/push_notification/repository/push_notification_repository.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';

final pushNotificationControllerProvider =
    StateNotifierProvider<PushNotificationController, bool>(
  (ref) => PushNotificationController(
    authController: ref.read(authControllerProvider.notifier),
    userController: ref.read(userControllerProvider.notifier),
    pushNotificationRepository: ref.read(pushNotificationRepositoryProvider),
  ),
);

class PushNotificationController extends StateNotifier<bool> {
  final PushNotificationRepository _pushNotificationRepository;
  final UserController _userController;

  PushNotificationController({
    required AuthController authController,
    required PushNotificationRepository pushNotificationRepository,
    required UserController userController,
  })  : _pushNotificationRepository = pushNotificationRepository,
        _userController = userController,
        super(false);

  Future<void> sendPushNotification(
    String token,
    String message,
    String title,
    Map<String, dynamic> payload,
    String type,
  ) async {
    await _pushNotificationRepository.sendFCMNotification(
      token,
      message,
      title,
      payload,
      type,
    );
  }

  Future<void> sendMultipleFCMNotifications(
    List<String> uids,
    String message,
    String title,
    Map<String, dynamic> payload,
    String type,
  ) async {
    List<String> tokens = [];
    for (var uid in uids) {
      final token = await _userController.getUserDeviceTokens(uid);
      tokens.add(token);
    }
    await _pushNotificationRepository.sendMultipleFCMNotifications(
      tokens,
      message,
      title,
      payload,
      type,
    );
  }
}
