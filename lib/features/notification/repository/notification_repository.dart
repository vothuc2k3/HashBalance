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

  //SEND NOTIFICATION
  FutureVoid sendNotification(NotificationModel notif) async {
    try {
      await _notification.doc().set(notif.toMap());
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //GET ALL THE NOTIFICATION
  Stream<List<NotificationModel>?> getNotificationByUid(String uid) {
    return _notification
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
      (event) {
        List<NotificationModel> notifs = [];
        for (var notif in event.docs) {
          final data = notif.data() as Map<String, dynamic>;
          notifs.add(
            NotificationModel(
              id: data['id'] as String,
              uid: uid,
              type: data['type'] as String,
              title: data['title'] as String,
              message: data['message'] as String,
              createdAt: data['createdAt'] as Timestamp,
              read: data['read'] as bool,
            ),
          );
        }
        return notifs;
      },
    );
  }

  //REFERENCE ALL THE FRIEND REQUESTS
  CollectionReference get _notification =>
      _firestore.collection(FirebaseConstants.friendRequestCollection);
}
