import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/common/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/friend_request_model.dart';
import 'package:hash_balance/models/user_model.dart';

final friendRepositoryProvider = Provider((ref) {
  return FriendRepository(firestore: ref.read(firebaseFirestoreProvider));
});

class FriendRepository {
  final FirebaseFirestore _firestore;

  FriendRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  //SEND FRIEND REQUEST
  FutureVoid sendFriendRequest(FriendRequest request) async {
    try {
      await _friendRequest.doc(request.id).set(request.toMap());
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //CANCEL FRIEND REQUEST
  FutureVoid cancelFriendRequest(String requestId) async {
    try {
      await _friendRequest.doc(requestId).delete();
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //GET THE SEND REQUEST STATUS
  Stream<FriendRequest?> getFriendRequestStatus(String requestId) {
    try {
      return _friendRequest.doc(requestId).snapshots().map((snapshot) {
        final data = snapshot.data();
        if (data != null) {
          final docData = data as Map<String, dynamic>;
          return FriendRequest(
            id: requestId,
            requestUid: docData['requestUid'] as String,
            targetUid: docData['targetUid'] as String,
            createdAt: docData['createdAt'] as Timestamp,
          );
        } else {
          return null;
        }
      });
    } on FirebaseException catch (e) {
      throw left(Failures(e.message!));
    } catch (e) {
      throw left(Failures(e.toString()));
    }
  }

  //ACCEPT FRIEND REQUEST
  FutureVoid acceptFriendRequest(
    UserModel currentUser,
    UserModel targetUser,
  ) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      UserModel currentUserCopy = currentUser.copyWith();
      UserModel targetUserCopy = targetUser.copyWith();
      currentUserCopy.friends.add(targetUserCopy.uid);
      targetUserCopy.friends.add(currentUserCopy.uid);
      batch.update(_users.doc(currentUser.uid), {
        'friends': currentUserCopy.friends,
      });
      batch.update(_users.doc(targetUserCopy.uid), {
        'friends': targetUserCopy.friends,
      });
      final uids = [currentUser.uid, targetUser.uid];
      uids.sort();
      final requestId = uids.join('_');
      await _friendRequest.doc(requestId).delete();
      await batch.commit();
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //UNFRIEND
  FutureVoid unfriend(
    UserModel currentUser,
    UserModel targetUser,
  ) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      UserModel currentUserCopy = currentUser.copyWith();
      UserModel targetUserCopy = targetUser.copyWith();

      currentUserCopy.friends.remove(targetUserCopy.uid);
      targetUserCopy.friends.remove(currentUserCopy.uid);

      batch.update(_users.doc(currentUser.uid), {
        'friends': currentUserCopy.friends,
      });
      batch.update(_users.doc(targetUserCopy.uid), {
        'friends': targetUserCopy.friends,
      });

      await batch.commit();
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //REFERENCE ALL THE FRIEND REQUESTS
  CollectionReference get _friendRequest =>
      _firestore.collection(FirebaseConstants.friendRequestCollection);
  //REFERENCE ALL THE FRIEND REQUESTS
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);
}
