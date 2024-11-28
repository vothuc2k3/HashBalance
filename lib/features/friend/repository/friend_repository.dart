import 'package:hash_balance/models/block_model.dart';
import 'package:hash_balance/models/conbined_models/block_data_model.dart';
import 'package:hash_balance/models/conbined_models/mutual_friend_model.dart';
import 'package:rxdart/rxdart.dart';
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
import 'package:tuple/tuple.dart';

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

  //REFERENCE ALL THE BLOCKS
  CollectionReference get _blocks =>
      _firestore.collection(FirebaseConstants.blocksCollection);

  //SEND FRIEND REQUEST
  Future<Either<Failures, void>> sendFriendRequest(
      FriendRequest request) async {
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
  Future<Either<Failures, void>> acceptFriendRequest(
      Friendship friendship) async {
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

  Stream<bool> getFriendshipStatus({required String uids}) {
    return _friendship.doc(uids).snapshots().map((snapshot) {
      return snapshot.exists;
    });
  }

  Future<List<UserModel>> fetchFriendsByUser(String uid) async {
    final results = await Future.wait([
      _friendship.where('uid1', isEqualTo: uid).get(),
      _friendship.where('uid2', isEqualTo: uid).get(),
    ]);
    final documents = results.expand((result) => result.docs).toList();

    final friendUids = documents.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['uid1'] == uid ? data['uid2'] : data['uid1'];
    }).toSet();

    List<UserModel> friends = [];

    for (String friendUid in friendUids) {
      final userDoc = await _users.doc(friendUid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        friends.add(UserModel.fromMap(data));
      }
    }

    return friends;
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

  Future<Either<Failures, void>> unfollowUser(
      String currentUid, String targetUid) async {
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

  Stream<bool> getFollowingStatus({
    required String currentUid,
    required String targetUid,
  }) {
    return _follower
        .where('followerUid', isEqualTo: currentUid)
        .where('targetUid', isEqualTo: targetUid)
        .snapshots()
        .map((event) {
      return event.docs.isNotEmpty;
    });
  }

  Future<List<FriendRequesterDataModel>> fetchFriendRequestsByUser(String uid) async {
    final snapshot = await _friendRequest
        .where('targetUid', isEqualTo: uid)
        .get();

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
  }

  Stream<bool> isBlockedByCurrentUser({
    required String currentUid,
    required String blockUid,
  }) {
    return _blocks
        .where('uid', isEqualTo: currentUid)
        .where('blockUid', isEqualTo: blockUid)
        .snapshots()
        .map((event) {
      return event.docs.isNotEmpty;
    });
  }

  Stream<bool> isBlockedByTargetUser({
    required String currentUid,
    required String targetUid,
  }) {
    return _blocks
        .where('uid', isEqualTo: targetUid)
        .where('blockUid', isEqualTo: currentUid)
        .snapshots()
        .map((event) {
      return event.docs.isNotEmpty;
    });
  }

  Stream<Tuple4<bool, bool, bool, bool>> getCombinedStatus({
    required String currentUid,
    required String targetUid,
    required String friendshipUids,
  }) {
    Stream<bool> hasBlockedStream =
        isBlockedByCurrentUser(currentUid: currentUid, blockUid: targetUid);
    Stream<bool> isBlockedStream =
        isBlockedByTargetUser(currentUid: currentUid, targetUid: targetUid);
    Stream<bool> followingStatusStream =
        getFollowingStatus(currentUid: currentUid, targetUid: targetUid);
    Stream<bool> friendshipStatusStream =
        getFriendshipStatus(uids: friendshipUids);
    return Rx.combineLatest4(
      hasBlockedStream,
      isBlockedStream,
      followingStatusStream,
      friendshipStatusStream,
      (hasBlocked, isBlocked, isFollowing, isFriend) {
        return Tuple4(hasBlocked, isBlocked, isFollowing, isFriend);
      },
    );
  }

  Stream<List<BlockDataModel>?> fetchBlockedUsers(String currentUid) {
    return _blocks
        .where('uid', isEqualTo: currentUid)
        .snapshots()
        .asyncMap((snapshot) async {
      List<BlockDataModel> blockDataModels = [];
      final snapshotData = snapshot.docs;
      for (final doc in snapshotData) {
        final data = doc.data() as Map<String, dynamic>;
        final blockUid = data['blockUid'];
        final blockId = data['id'];
        final userDoc = await _users.doc(blockUid).get();
        final blockDoc = await _blocks.doc(blockId).get();
        if (userDoc.exists && blockDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final blockDataModel = BlockDataModel(
            block: BlockModel.fromMap(data),
            user: UserModel.fromMap(userData),
          );
          blockDataModels.add(blockDataModel);
        }
      }
      return blockDataModels;
    });
  }

  Future<int> getMutualFriendsCount(String uid1, String uid2) async {
    final friends1 = await fetchFriendsByUser(uid1);
    if (friends1.isEmpty) return 0;

    final friendUids1 = friends1.map((friend) => friend.uid).toSet();

    final friends2 = await fetchFriendsByUser(uid2);
    if (friends2.isEmpty) return 0;

    final mutualFriends =
        friends2.where((friend) => friendUids1.contains(friend.uid)).length;
    return mutualFriends;
  }

  Future<List<MutualFriend>> getMutualFriends(String uid1, String uid2) async {
    final friends1 = await fetchFriendsByUser(uid1);
    if (friends1.isEmpty) return [];

    final friendUids1 = friends1.map((friend) => friend.uid).toSet();

    final friends2 = await fetchFriendsByUser(uid2);
    if (friends2.isEmpty) return [];

    final mutualFriends = friends2
        .where((friend) => friendUids1.contains(friend.uid))
        .map((friend) {
      final isFriend = friends1.any((f) => f.uid == friend.uid);
      return MutualFriend(user: friend, isFriend: isFriend);
    }).toList();

    return mutualFriends;
  }

  Future<List<String>> getUserFollowerUids(String uid) async {
    final docs = await _follower.where('targetUid', isEqualTo: uid).get();
    return docs.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['followerUid'] as String;
    }).toList();
  }

  
}
