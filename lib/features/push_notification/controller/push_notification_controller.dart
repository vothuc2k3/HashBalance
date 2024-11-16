import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/push_notification/repository/push_notification_repository.dart';

final pushNotificationControllerProvider =
    StateNotifierProvider<PushNotificationController, bool>(
  (ref) => PushNotificationController(
    authController: ref.read(authControllerProvider.notifier),
    pushNotificationRepository: ref.read(pushNotificationRepositoryProvider),
  ),
);

class PushNotificationController extends StateNotifier<bool> {
  final PushNotificationRepository _pushNotificationRepository;

  PushNotificationController({
    required AuthController authController,
    required PushNotificationRepository pushNotificationRepository,
  })  : _pushNotificationRepository = pushNotificationRepository,
        super(false);

  Future<void> sendPushNotification(
    List<String> tokens,
    String message,
    String title,
    Map<String, dynamic> payload,
    String type,
  ) async {
    await _pushNotificationRepository.sendFCMNotification(
      tokens,
      message,
      title,
      payload,
      type,
    );
  }
}
