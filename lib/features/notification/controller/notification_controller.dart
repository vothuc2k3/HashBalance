import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/notification/repository/notification_repository.dart';
import 'package:hash_balance/models/notification_model.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final getUnreadNotifCountProvider =
    StreamProvider.family.autoDispose((ref, String uid) {
  return ref
      .watch(notificationControllerProvider.notifier)
      .getUnreadNotificationCount(uid);
});

final deleteNotifProvider =
    FutureProvider.family.autoDispose((ref, String notifId) {
  return ref
      .watch(notificationControllerProvider.notifier)
      .deleteNotif(notifId);
});

final getInitialNotifsProvider =
    StreamProvider.family.autoDispose((ref, String uid) {
  return ref
      .watch(notificationControllerProvider.notifier)
      .getInitialNotification(uid);
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

  Future<Either<Failures, void>> addNotification(
    String targetUid,
    NotificationModel notification,
  ) async {
    try {
      await _notificationRepository.addNotification(targetUid, notification);
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  // GET ALL THE NOTIFICATION
  Stream<List<NotificationModel>?> getInitialNotification(String uid) {
    return _notificationRepository.getInitialNotification(uid);
  }

  Future<void> markAsRead(String notifId) async {
    final uid = _ref.read(userProvider)!.uid;
    await _notificationRepository.markAsRead(uid, notifId);
  }

  Future<void> deleteNotif(String notifId) async {
    final uid = _ref.read(userProvider)!.uid;
    await _notificationRepository.deleteNotification(uid, notifId);
  }

  Future<Either<Failures, void>> clearAllNotifications() async {
    final uid = _ref.read(userProvider)!.uid;
    try {
      return await _notificationRepository.clearAllNotifications(uid);
    } catch (e, stackTrace) {
      await Sentry.captureException(
        e,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'message': 'Error while clearing all notifications for user: $uid',
        }),
      );
      return Left(
          Failures('Failed to clear all notifications. Please try again.'));
    }
  }

  Stream<int> getUnreadNotificationCount(String uid) {
    return _notificationRepository.getUnreadNotificationCount(uid);
  }

  Future<List<NotificationModel>?> loadMoreNotifications(
    NotificationModel lastNotification,
  ) async {
    final uid = _ref.read(userProvider)!.uid;
    return _notificationRepository.loadMoreNotifications(uid, lastNotification);
  }
}
