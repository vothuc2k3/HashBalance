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
import 'package:hash_balance/models/conbined_models/newsfeed_data_model.dart';
import 'package:hash_balance/models/conbined_models/poll_data_model.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';
import 'package:hash_balance/models/poll_model.dart';
import 'package:hash_balance/models/poll_option_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';

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
  CollectionReference get _polls =>
      _firestore.collection(FirebaseConstants.pollsCollection);
  //GET THE COMMUNITIES DATA
  CollectionReference get _pollOptions =>
      _firestore.collection(FirebaseConstants.pollOptionsCollection);

  //CREATE A WHOLE NEW COMMUNITY
  Future<Either<Failures, String>> createCommunity(Community community) async {
    try {
      var communityDoc = await _communities.doc(community.id).get();

      if (communityDoc.exists) {
        throw 'The name is already exists!';
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
  Stream<List<Community>?> getTopCommunitiesList() {
    return _communities.snapshots().asyncMap((communitySnapshot) async {
      final communities = <Community>[];
      final communityCountMap = <String, int>{};

      final memberCountFutures = communitySnapshot.docs.map((doc) async {
        final communityId = doc.id;
        final communityData = doc.data() as Map<String, dynamic>;

        final memberCountSnapshot = await _communityMembership
            .where('communityId', isEqualTo: communityId)
            .get();
        final memberCount = memberCountSnapshot.size;
        communityCountMap[communityId] = memberCount;

        communities.add(
          Community.fromMap(communityData),
        );
      });

      await Future.wait(memberCountFutures);

      communities.sort((a, b) =>
          communityCountMap[b.id]!.compareTo(communityCountMap[a.id]!));

      return communities;
    });
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

  Stream<List<NewsfeedCombinedModel>> fetchCommunityPosts(String communityId) {
    // Lấy stream từ Firestore cho posts và polls
    final communityPostsStream = _posts
        .where('communityId', isEqualTo: communityId)
        .where('status', isEqualTo: 'Approved')
        .snapshots();

    final communityPollsStream =
        _polls.where('communityId', isEqualTo: communityId).snapshots();

    return communityPostsStream.asyncMap((communityPosts) async {
      // Khởi tạo danh sách để lưu trữ dữ liệu từ posts và polls
      List<NewsfeedCombinedModel> newsfeedDataList = [];

      // Duyệt qua từng document của posts
      for (final postDoc in communityPosts.docs) {
        final postData = Post.fromMap(postDoc.data() as Map<String, dynamic>);

        final authorDoc = await _users.doc(postData.uid).get();
        final authorData =
            UserModel.fromMap(authorDoc.data() as Map<String, dynamic>);

        final postDataModel = PostDataModel(
          post: postData,
          author: authorData,
        );

        newsfeedDataList.add(
          NewsfeedCombinedModel(post: postDataModel, poll: null),
        );
      }

      // Duyệt qua các polls
      final communityPolls = await communityPollsStream.first;

      for (final pollDoc in communityPolls.docs) {
        final pollData = Poll.fromMap(pollDoc.data() as Map<String, dynamic>);

        final authorDoc = await _users.doc(pollData.uid).get();
        final authorData =
            UserModel.fromMap(authorDoc.data() as Map<String, dynamic>);

        // Lấy các tùy chọn của cuộc thăm dò
        final optionsQuery =
            await _pollOptions.where('pollId', isEqualTo: pollData.id).get();
        List<PollOption> options = optionsQuery.docs
            .map((option) =>
                PollOption.fromMap(option.data() as Map<String, dynamic>))
            .toList();

        // Tạo PollDataModel và thêm vào danh sách
        final pollDataModel = PollDataModel(
          poll: pollData,
          author: authorData,
          options: options,
        );

        newsfeedDataList.add(
          NewsfeedCombinedModel(post: null, poll: pollDataModel),
        );
      }

      // Sắp xếp các bài đăng và polls theo thời gian tạo
      newsfeedDataList.sort((a, b) {
        final postDateA = a.post?.post.createdAt ?? Timestamp(0, 0);
        final pollDateA = a.poll?.poll.createdAt ?? Timestamp(0, 0);
        final postDateB = b.post?.post.createdAt ?? Timestamp(0, 0);
        final pollDateB = b.poll?.poll.createdAt ?? Timestamp(0, 0);

        return pollDateB.toDate().compareTo(pollDateA.toDate()) +
            postDateB.toDate().compareTo(postDateA.toDate());
      });

      return newsfeedDataList;
    });
  }

  Stream<List<Community>> fetchCommunities() {
    return _communities.snapshots().map(
      (event) {
        List<Community> communities = event.docs.map(
          (doc) {
            return Community.fromMap(doc.data() as Map<String, dynamic>);
          },
        ).toList();
        return communities;
      },
    );
  }

  Stream<CurrentUserRoleModel?> getCurrentUserRole(
      String communityId, String uid) {
    final uids = getMembershipId(uid, communityId);
    return _communityMembership.doc(uids).snapshots().map((event) {
      if (event.exists) {
        final data = event.data() as Map<String, dynamic>;
        return CurrentUserRoleModel(
          uid: uid,
          communityId: communityId,
          role: data['role'] as String,
          status: data['status'] as String,
        );
      } else {
        return null;
      }
    });
  }
}
