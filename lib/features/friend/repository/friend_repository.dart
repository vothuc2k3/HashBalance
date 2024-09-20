import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/models/conbined_models/friend_requester_data_model.dart';
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

  //REFERENCE ALL THE FRIENDSHIPS
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);
  //REFERENCE ALL THE FRIENDSHIPS
  CollectionReference get _friendship =>
      _firestore.collection(FirebaseConstants.friendshipCollection);
  //REFERENCE ALL THE FRIEND REQUESTS
  CollectionReference get _friendRequest =>
      _firestore.collection(FirebaseConstants.friendRequestCollection);
  //REFERENCE ALL THE FOLLOWER
  CollectionReference get _follower =>
      _firestore.collection(FirebaseConstants.followerCollection);

  //SEND FRIEND REQUEST
  Future<Either<Failures, void>> sendFriendRequest(FriendRequest request) async {
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
  Future<Either<Failures, void>> cancelFriendRequest(String requestId) async {
    try {
      await _friendRequest.doc(requestId).delete();
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //DECLINE FRIEND REQUEST
  Future<Either<Failures, void>> declineFriendRequest(String requestId) async {
    try {
      await _friendRequest.doc(requestId).update({
        'status': Constants.friendRequestStatusDeclined,
      });
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
          return FriendRequest.fromMap(docData);
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
  Future<Either<Failures, void>> acceptFriendRequest(Friendship friendship) async {
    try {
      final uids = getUids(friendship.uid1, friendship.uid2);

      await _friendship.doc(uids).set(friendship.toMap());

      await _friendRequest.doc(uids).update({
        'status': Constants.friendRequestStatusAccepted,
      });
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //UNFRIEND
  Future<Either<Failures, void>> unfriend(String uids) async {
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

  Stream<List<UserModel>> fetchFriendsByUser(String uid) {
    return Stream.fromFuture(
      Future.wait([
        _friendship.where('uid1', isEqualTo: uid).get(),
        _friendship.where('uid2', isEqualTo: uid).get(),
      ]),
    ).asyncMap((results) async {
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

      return friendQuery.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromMap(data);
      }).toList();
    });
  }

  Future<Either<Failures, void>> followUser(Follower followerModel) async {
    try {
      await _follower.doc(followerModel.id).set(followerModel.toMap());
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, void>> unfollowUser(String currentUid, String targetUid) async {
    try {
      final docs = await _follower
          .where('followerUid', isEqualTo: currentUid)
          .where('targetUid', isEqualTo: targetUid)
          .get();
      for (var doc in docs.docs) {
        await doc.reference.delete();
      }
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<bool> getFollowingStatus(String currentUid, String targetUid) {
    return _follower
        .where('followerUid', isEqualTo: currentUid)
        .where('targetUid', isEqualTo: targetUid)
        .snapshots()
        .map((event) {
      return event.docs.isNotEmpty;
    });
  }

  Stream<List<FriendRequesterDataModel>> fetchFriendRequestsByUser(String uid) {
    return _friendRequest
        .where('targetUid', isEqualTo: uid)
        .snapshots()
        .asyncMap((snapshot) async {
      List<FriendRequesterDataModel> friendRequestDataModels = [];

      final friendRequests = snapshot.docs.map((doc) {
        return FriendRequest.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();

      for (var request in friendRequests) {
        final userDoc = await _users.doc(request.requestUid).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final userModel = UserModel.fromMap(userData);

          final friendRequesterDataModel = FriendRequesterDataModel(
            friendRequest: request,
            requester: userModel,
          );

          friendRequestDataModels.add(friendRequesterDataModel);
        }
      }

      return friendRequestDataModels;
    });
  }
}
