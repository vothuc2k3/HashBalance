// ignore_for_file: unused_field

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/push_notification/repository/push_notification_repository.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

final pushNotificationControllerProvider =
    StateNotifierProvider<PushNotificationController, bool>(
  (ref) => PushNotificationController(
      pushNotificationRepository: ref.read(pushNotificationRepositoryProvider),
      ref: ref),
);

class PushNotificationController extends StateNotifier<bool> {
  final PushNotificationRepository _pushNotificationRepository;
  final Ref _ref;

  PushNotificationController({
    required PushNotificationRepository pushNotificationRepository,
    required Ref ref,
  })  : _pushNotificationRepository = pushNotificationRepository,
        _ref = ref,
        super(false);

  Future<void> setExternalUserId() async {
    final currentUser = _ref.watch(userProvider);
    await OneSignal.User.addAlias('external_id', currentUser!.uid);
  }

  Future<void> sendPushNotification() async {
    _pushNotificationRepository.sendPushNotification();
  }
}
