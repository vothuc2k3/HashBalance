import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/post_data_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';

final newsfeedRepositoryProvider = Provider((ref) {
  return NewsfeedRepository(firestore: ref.watch(firebaseFirestoreProvider));
});

class NewsfeedRepository {
  final FirebaseFirestore _firestore;

  NewsfeedRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  //REFERENCE ALL THE USERS
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);
  //REFERENCE ALL THE COMMUNITIES
  CollectionReference get _communities =>
      _firestore.collection(FirebaseConstants.communitiesCollection);

  //GET THE COMMUNITIES' POSTS BY CURRENT USER
  Future<List<PostDataModel>> getJoinedCommunitiesPosts(String uid) async {
    final data = await _communityMembership.where('uid', isEqualTo: uid).get();
    final communitiesId =
        data.docs.map((doc) => doc['communityId'] as String).toList();

    final List<PostDataModel> postDataList = [];

    for (var communityId in communitiesId) {
      final communityPosts = await _posts
          .where('communityId', isEqualTo: communityId)
          .where('status', isEqualTo: 'Approved')
          .orderBy('createdAt', descending: true)
          .get();

      if (communityPosts.docs.isNotEmpty) {
        await Future.wait(communityPosts.docs.map((postDoc) async {
          final post = Post.fromMap(postDoc.data() as Map<String, dynamic>);

          final authorDoc = await _users.doc(post.uid).get();
          final author =
              UserModel.fromMap(authorDoc.data() as Map<String, dynamic>);

          final communityDoc = await _communities.doc(communityId).get();
          final community =
              Community.fromMap(communityDoc.data() as Map<String, dynamic>);

          postDataList.add(PostDataModel(
            post: post,
            author: author,
            community: community,
          ));
        }));
      }
    }

    return postDataList;
  }

  //GET ALL POST OF A COMMUNITY
  Future<List<PostDataModel>> getCommunityPosts(String communityId) async {
    try {
      final communityPosts = await _posts
          .where('communityId', isEqualTo: communityId)
          .where('status', isEqualTo: 'Approved')
          .orderBy('createdAt', descending: true)
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

      return postDataModels;
    } on FirebaseException catch (e) {
      throw e.toString();
    }
  }

  //REFERENCE THE POSTS DATA
  CollectionReference get _posts =>
      _firestore.collection(FirebaseConstants.postsCollection);
  //REFERENCE THE COMMUNITIES DATA
  CollectionReference get _communityMembership =>
      _firestore.collection(FirebaseConstants.communityMembershipCollection);
}
