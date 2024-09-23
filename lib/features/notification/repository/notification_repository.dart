import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/models/notification_model.dart';

final notificationRepositoryProvider = Provider((ref) {
  return NotificationRepository(firestore: ref.read(firebaseFirestoreProvider));
});

class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  //REFERENCE ALL THE USERS
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);

  Future<Either<Failures, void>> addNotification(
    String targetUid,
    NotificationModel notification,
  ) async {
    try {
      await _users
          .doc(targetUid)
          .collection(FirebaseConstants.notificationCollection)
          .doc(notification.id)
          .set(notification.toMap());
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //GET ALL THE NOTIFICATION
  Stream<List<NotificationModel>?> getInitialNotification(String uid) {
    return _users
        .doc(uid)
        .collection(FirebaseConstants.notificationCollection)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map(
      (event) {
        List<NotificationModel> notifs = [];
        for (var notif in event.docs) {
          final data = notif.data();
          notifs.add(
            NotificationModel.fromMap(data),
          );
        }
        return notifs;
      },
    );
  }

  //MARK AS READ THE NOTIFICATION
  Future<void> markAsRead(String uid, String notifId) async {
    final query = await _users
        .doc(uid)
        .collection(FirebaseConstants.notificationCollection)
        .where('id', isEqualTo: notifId)
        .get();
    for (var doc in query.docs) {
      final data = doc.data();
      bool isRead = data['isRead'] as bool;
      if (isRead == false) {
        isRead = true;
        await doc.reference.update({'isRead': isRead});
      }
    }
  }

  Future<void> deleteNotification(String uid, String notifId) async {
    await _users
        .doc(uid)
        .collection(FirebaseConstants.notificationCollection)
        .doc(notifId)
        .delete();
  }

  Future<Either<Failures, void>> clearAllNotifications(String uid) async {
    try {
      await _users
          .doc(uid)
          .collection(FirebaseConstants.notificationCollection)
          .get()
          .then((querySnapshot) {
        for (var doc in querySnapshot.docs) {
          doc.reference.delete();
        }
      });
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<int> getUnreadNotificationCount(String uid) {
    return _users
        .doc(uid)
        .collection(FirebaseConstants.notificationCollection)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((event) => event.docs.length);
  }

  Future<List<NotificationModel>?> loadMoreNotifications(
      String uid, NotificationModel lastNotification) async {
    final query = await _users
        .doc(uid)
        .collection(FirebaseConstants.notificationCollection)
        .orderBy('createdAt', descending: true)
        .startAfter([lastNotification.createdAt])
        .limit(10)
        .get();
    return query.docs
        .map((doc) => NotificationModel.fromMap(doc.data()))
        .toList();
  }
}
