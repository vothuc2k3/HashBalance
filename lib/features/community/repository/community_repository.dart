import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/models/community_membership_model.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/conbined_models/current_user_role_model.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:tuple/tuple.dart';

final communityRepositoryProvider = Provider((ref) {
  return CommunityRepository(firestore: ref.watch(firebaseFirestoreProvider));
});

class CommunityRepository {
  final FirebaseFirestore _firestore;

  CommunityRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  //GET THE COMMUNITIES DATA
  CollectionReference get _communities =>
      _firestore.collection(FirebaseConstants.communitiesCollection);
  //GET THE COMMUNITIES DATA
  CollectionReference get _communityMembership =>
      _firestore.collection(FirebaseConstants.communityMembershipCollection);
  //GET THE COMMUNITIES DATA
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);
  //GET THE COMMUNITIES DATA
  CollectionReference get _posts =>
      _firestore.collection(FirebaseConstants.postsCollection);
  //GET THE COMMUNITIES DATA
  CollectionReference get _suspendedUsers =>
      _firestore.collection(FirebaseConstants.suspendedUsersCollection);
  //GET THE COMMUNITIES DATA

  //CREATE A WHOLE NEW COMMUNITY
  Future<Either<Failures, String>> createCommunity(Community community) async {
    try {
      final communityDoc = await _communities.doc(community.id).get();

      if (communityDoc.exists) {
        return left(Failures('The name is already exists!'));
      }

      await _communities.doc(community.id).set(community.toMap());
      return right('Successfully created community');
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //GET THE COMMUNITIES BY CURRENT USER
  Stream<List<Community>> getUserCommunities(String uid) {
    return _communityMembership
        .where('uid', isEqualTo: uid)
        .snapshots()
        .asyncMap((event) async {
      final communities = <Community>[];
      for (var doc in event.docs) {
        final communityId =
            (doc.data() as Map<String, dynamic>)['communityId'] as String;
        final communitySnapshot = await _communities.doc(communityId).get();
        final data = communitySnapshot.data() as Map<String, dynamic>;
        communities.add(
          Community.fromMap(data),
        );
      }
      return communities;
    });
  }

  Stream<List<Community>> getMyCommunities(String uid) {
    return _communityMembership
        .where('uid', isEqualTo: uid)
        .where('role', isEqualTo: Constants.moderatorRole)
        .snapshots()
        .asyncMap((event) async {
      final communities = <Community>[];
      for (var doc in event.docs) {
        final communityId =
            (doc.data() as Map<String, dynamic>)['communityId'] as String;
        final communitySnapshot = await _communities.doc(communityId).get();
        final data = communitySnapshot.data() as Map<String, dynamic>;
        communities.add(Community.fromMap(data));
      }
      return communities;
    });
  }

  //LET USER JOIN COMMUNITY
  Future<Either<Failures, void>> joinCommunity(
      CommunityMembership membership) async {
    try {
      final membershipDoc = await _communityMembership.doc(membership.id).get();
      if (membershipDoc.exists) {
        await _communityMembership
            .doc(membership.id)
            .update(membership.toMap());
      } else {
        await _communityMembership.doc(membership.id).set(membership.toMap());
      }
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //LET USER JOIN COMMUNITY
  Future<Either<Failures, void>> leaveCommunity(String membershipId) async {
    try {
      await _communityMembership.doc(membershipId).delete();
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //GET MOST JOINED COMMUNITIES
  Future<List<Tuple2<Community, int>>> getTopCommunitiesList() async {
    final communitySnapshot = await _communities
        .where('type', whereIn: ['Public', 'Restricted']).get();
    final communityCountMap = <String, int>{};

    final memberCountFutures = communitySnapshot.docs.map((doc) async {
      final communityId = doc.id;
      final communityData = doc.data() as Map<String, dynamic>;

      final memberCountSnapshot = await _communityMembership
          .where('communityId', isEqualTo: communityId)
          .get();
      final memberCount = memberCountSnapshot.size;
      communityCountMap[communityId] = memberCount;

      return Tuple2(Community.fromMap(communityData), memberCount);
    });

    final communityTuples = await Future.wait(memberCountFutures);

    communityTuples.sort((a, b) => b.item2.compareTo(a.item2));

    return communityTuples;
  }

  //CHECK IF THE USER IS MEMBER OF COMMUNITY
  Stream<bool> getMemberStatus(String membershipId) {
    try {
      final snapshot = _communityMembership.doc(membershipId).snapshots();
      return snapshot.map((docSnapshot) {
        return docSnapshot.exists;
      });
    } on FirebaseException catch (e) {
      return Stream.error(Failures(e.message!));
    } catch (e) {
      return Stream.error(Failures(e.toString()));
    }
  }

  //GET MEMBER COUNT OF COMMUNITY
  Stream<int> getCommunityMemberCount(String communityId) {
    return _communityMembership
        .where('communityId', isEqualTo: communityId)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Stream<Community> getCommunityById(String communityId) {
    return _communities.doc(communityId).snapshots().map(
      (event) {
        final data = event.data() as Map<String, dynamic>;
        return Community.fromMap(data);
      },
    );
  }

  Future<Community> fetchCommunityById(String communityId) async {
    final doc = await _communities.doc(communityId).get();
    return Community.fromMap(doc.data() as Map<String, dynamic>);
  }

  // GET ALL POST OF A COMMUNITY
  Future<List<PostDataModel>> getCommunityPosts(String communityId) async {
    try {
      final communityPosts = await _posts
          .where('communityId', isEqualTo: communityId)
          .where('status', isEqualTo: 'Approved')
          .where('isPinned', isEqualTo: false)
          .get();

      final List<PostDataModel> postDataModels = [];

      for (final postDoc in communityPosts.docs) {
        final postData = Post.fromMap(postDoc.data() as Map<String, dynamic>);

        final authorDoc = await _users.doc(postData.uid).get();
        final authorData =
            UserModel.fromMap(authorDoc.data() as Map<String, dynamic>);

        final communityDoc = await _communities.doc(postData.communityId).get();
        final communityData =
            Community.fromMap(communityDoc.data() as Map<String, dynamic>);
        postDataModels.add(
          PostDataModel(
            post: postData,
            author: authorData,
            community: communityData,
          ),
        );
      }
      postDataModels
          .sort((a, b) => b.post.createdAt.compareTo(a.post.createdAt));
      return postDataModels;
    } on FirebaseException catch (e) {
      throw e.toString();
    }
  }

  Stream<List<PostDataModel>> fetchCommunityPosts(String communityId) {
    final communityPostsStream = _posts
        .where('communityId', isEqualTo: communityId)
        .where('status', isEqualTo: 'Approved')
        .snapshots();

    return communityPostsStream.asyncMap((communityPosts) async {
      List<PostDataModel> postDataModels = [];

      for (final postDoc in communityPosts.docs) {
        final postData = Post.fromMap(postDoc.data() as Map<String, dynamic>);

        final authorDoc = await _users.doc(postData.uid).get();
        final authorData =
            UserModel.fromMap(authorDoc.data() as Map<String, dynamic>);

        final postDataModel = PostDataModel(
          post: postData,
          author: authorData,
        );

        postDataModels.add(postDataModel);
      }
      postDataModels
          .sort((a, b) => b.post.createdAt.compareTo(a.post.createdAt));
      return postDataModels;
    });
  }

  Future<List<Community>> fetchCommunities() async {
    try {
      final snapshot = await _communities
          .where('type', whereIn: ['Public', 'Restricted']).get();
      List<Community> communities = snapshot.docs.map((doc) {
        return Community.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
      return communities;
    } on FirebaseException catch (e) {
      throw e.toString();
    }
  }

  Stream<CurrentUserRoleModel?> getCurrentUserRole(
      String communityId, String uid) {
    final uids = getMembershipId(uid: uid, communityId: communityId);
    return _communityMembership.doc(uids).snapshots().asyncMap((event) async {
      if (event.exists) {
        final data = event.data() as Map<String, dynamic>;
        final userDoc = await _users.doc(data['uid']).get();
        final user = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        return CurrentUserRoleModel(
          user: user,
          communityId: communityId,
          role: data['role'] as String,
          status: data['status'] as String,
          joinedAt: data['joinedAt'] as Timestamp,
          isCreator: data['isCreator'] as bool,
        );
      } else {
        return null;
      }
    });
  }

  Future<Either<Failures, bool>> fetchSuspendStatus({
    required String communityId,
    required String uid,
  }) async {
    try {
      final snapshot = await _suspendedUsers
          .where('communityId', isEqualTo: communityId)
          .where('uid', isEqualTo: uid)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return right(true);
      } else {
        return right(false);
      }
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    }
  }

  Future<String> getMemberRole(String membershipId) async {
    final snapshot = await _communityMembership.doc(membershipId).get();
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      return data['role'] as String;
    } else {
      return '';
    }
  }

  Future<List<CurrentUserRoleModel?>> getInitialCommunityMembers(
      String communityId) async {
    final snapshot = await _communityMembership
        .where('communityId', isEqualTo: communityId)
        .orderBy('joinedAt', descending: true)
        .limit(20)
        .get();

    final members = <CurrentUserRoleModel?>[];
    final uids = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['uid'] as String;
    }).toList();

    final userDocs = await _users.where('uid', whereIn: uids).get();

    final userMap = {
      for (var user in userDocs.docs)
        (user.data() as Map<String, dynamic>)['uid']:
            user.data() as Map<String, dynamic>
    };

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final uid = data['uid'] as String;

      final userDoc = userMap[uid];
      if (userDoc != null) {
        final user = UserModel.fromMap(userDoc);
        members.add(CurrentUserRoleModel(
          user: user,
          communityId: communityId,
          role: data['role'] as String,
          status: data['status'] as String,
          joinedAt: data['joinedAt'] as Timestamp,
          isCreator: data['isCreator'] as bool,
        ));
      }
    }

    return members;
  }

  Future<List<CurrentUserRoleModel?>> getMoreCommunityMembers(
      String communityId, Timestamp? lastJoinedAt) async {
    if (lastJoinedAt == null) {
      return [];
    }
    final snapshot = await _communityMembership
        .where('communityId', isEqualTo: communityId)
        .orderBy('joinedAt', descending: true)
        .startAfter([lastJoinedAt])
        .limit(20)
        .get();

    final uids = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['uid'] as String;
    }).toList();

    final userDocs = await _users.where('uid', whereIn: uids).get();

    final userMap = {
      for (var user in userDocs.docs)
        (user.data() as Map<String, dynamic>)['uid']:
            user.data() as Map<String, dynamic>
    };

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final uid = data['uid'] as String;
      final userDoc = userMap[uid];

      if (userDoc != null) {
        final user = UserModel.fromMap(userDoc);
        return CurrentUserRoleModel(
          user: user,
          communityId: communityId,
          role: data['role'] as String,
          status: data['status'] as String,
          joinedAt: data['joinedAt'] as Timestamp,
          isCreator: data['isCreator'] as bool,
        );
      }
      return null;
    }).toList();
  }

  Future<List<String>> getMembershipUids(String communityId) async {
    final snapshot = await _communityMembership
        .where('communityId', isEqualTo: communityId)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['uid'] as String;
    }).toList();
  }

  Future<bool> isCommunityCreator({
    required String communityId,
    required String uid,
  }) async {
    final doc = await _communityMembership
        .doc(getMembershipId(uid: uid, communityId: communityId))
        .get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['isCreator'] as bool;
    }
    return false;
  }
}
