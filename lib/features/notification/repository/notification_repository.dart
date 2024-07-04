import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/common/constants/firebase_constants.dart';
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

  FutureVoid addNotification(
    String targetUid,
    NotificationModel notification,
  ) async {
    try {
      await _user
          .doc(targetUid)
          .collection('notification')
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
    return _user.doc(uid).collection('notification').snapshots().map(
      (event) {
        List<NotificationModel> notifs = [];
        for (var notif in event.docs) {
          final data = notif.data();
          notifs.add(
            NotificationModel(
              id: data['id'] as String,
              title: data['title'] as String,
              message: data['message'] as String,
              type: data['type'] as String,
              targetUid: data['targetUid'] as String? ?? '',
              postId: data['postId'] as String? ?? '',
              createdAt: data['createdAt'] as Timestamp,
              isRead: data['isRead'] as bool,
            ),
          );
        }
        return notifs;
      },
    );
  }

  //MARK AS READ THE NOTIFICATION
  Future<void> markAsRead(String uid, String notifId) async {
    final query = await _user
        .doc(uid)
        .collection('notification')
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

  //REFERENCE ALL THE USERS
  CollectionReference get _user =>
      _firestore.collection(FirebaseConstants.usersCollection);
}
