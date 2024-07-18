import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/common/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/models/follower_model.dart';
import 'package:hash_balance/models/friendship_model.dart';
import 'package:hash_balance/models/friendship_request_model.dart';
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
  Stream<FriendRequest?> getFriendRequestStatus(String uids) {
    try {
      return _friendRequest.doc(uids).snapshots().map((snapshot) {
        final data = snapshot.data();
        if (data != null) {
          final docData = data as Map<String, dynamic>;
          return FriendRequest(
            id: uids,
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
  FutureVoid acceptFriendRequest(Friendship friendship) async {
    try {
      final uids = getUids(friendship.uid1, friendship.uid2);

      await _friendship.doc(uids).set(friendship.toMap());

      await _friendRequest.doc(uids).delete();
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //UNFRIEND
  FutureVoid unfriend(String uids) async {
    try {
      await _friendship.doc(uids).delete();

      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<bool> getFriendshipStatus(String uids) {
    return _friendship.doc(uids).snapshots().map((snapshot) {
      return snapshot.exists;
    });
  }

  Future<List<UserModel>> fetchFriendsByUser(String uid) async {
    try {
      final query1 = _friendship.where('uid1', isEqualTo: uid).get();
      final query2 = _friendship.where('uid2', isEqualTo: uid).get();

      final results = await Future.wait([query1, query2]);

      final documents = results.expand((result) => result.docs).toList();

      final friendUids = documents.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['uid1'] == uid ? data['uid2'] : data['uid1'];
      }).toList();

      if (friendUids.isEmpty) {
        return [];
      }

      final friendQuery =
          await _users.where(FieldPath.documentId, whereIn: friendUids).get();

      // Chuyển đổi các tài liệu thành các đối tượng UserModel
      return friendQuery.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromMap(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  FutureVoid followUser(Follower followerModel) async {
    try {
      await _follower.doc(followerModel.id).set(followerModel.toMap());
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<bool> getFollowingStatus(String uids) {
    return _follower.doc(uids).snapshots().map((event) {
      return event.exists;
    });
  }

  //REFERENCE ALL THE FRIENDSHIPS
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);
  //REFERENCE ALL THE FRIENDSHIPS
  CollectionReference get _friendship =>
      _firestore.collection(FirebaseConstants.friendshipCollection);
  //REFERENCE ALL THE FRIEND REQUESTS
  CollectionReference get _friendRequest =>
      _firestore.collection(FirebaseConstants.friendRequestCollection);
  //REFERENCE ALL THE FRIEND REQUESTS
  CollectionReference get _follower =>
      _firestore.collection(FirebaseConstants.followerCollection);
}
