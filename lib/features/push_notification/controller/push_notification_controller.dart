import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/push_notification/repository/push_notification_repository.dart';

final pushNotificationControllerProvider =
    StateNotifierProvider<PushNotificationController, bool>(
  (ref) => PushNotificationController(
      authController: ref.read(authControllerProvider.notifier),
      pushNotificationRepository: ref.read(pushNotificationRepositoryProvider),
      ref: ref),
);

class PushNotificationController extends StateNotifier<bool> {
  final PushNotificationRepository _pushNotificationRepository;

  PushNotificationController({
    required AuthController authController,
    required PushNotificationRepository pushNotificationRepository,
    required Ref ref,
  })  : _pushNotificationRepository = pushNotificationRepository,
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
}
