import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
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
  //REFERENCE ALL THE USERS
  CollectionReference get _calls =>
      _firestore.collection(FirebaseConstants.callCollection);

  FutureVoid addNotification(
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
  Stream<List<NotificationModel>?> getNotificationByUid(String uid) {
    return _users
        .doc(uid)
        .collection(FirebaseConstants.notificationCollection)
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
}
