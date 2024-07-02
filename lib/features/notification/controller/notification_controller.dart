import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/notification/repository/notification_repository.dart';
import 'package:hash_balance/models/notification_model.dart';

final getNotifsProvider = StreamProvider.family((ref, String uid) {
  return ref
      .watch(notificationControllerProvider.notifier)
      .getNotificationByUid(uid);
});

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, bool>(
        (ref) => NotificationController(
              notificationRepository: ref.read(notificationRepositoryProvider),
              ref: ref,
            ));

class NotificationController extends StateNotifier<bool> {
  final NotificationRepository _notificationRepository;
  final Ref _ref;

  NotificationController({
    required NotificationRepository notificationRepository,
    required Ref ref,
  })  : _notificationRepository = notificationRepository,
        _ref = ref,
        super(false);

  FutureVoid addNotification(
    String targetUid,
    NotificationModel notification,
  ) async {
    state = true;
    try {
      await _notificationRepository.addNotification(targetUid, notification);
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    } finally {
      state = false;
    }
  }

  // GET ALL THE NOTIFICATION
  Stream<List<NotificationModel>?> getNotificationByUid(String uid) {
    return _notificationRepository.getNotificationByUid(uid);
  }

  void markAsRead(String notifId) {
    final uid = _ref.watch(userProvider)!.uid;
    _notificationRepository.markAsRead(uid, notifId);
  }
}
