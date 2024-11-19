import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';
import 'package:hash_balance/models/post_model.dart';

final newsfeedRepositoryProvider = Provider((ref) {
  return NewsfeedRepository(
    firestore: ref.read(firebaseFirestoreProvider),
    postController: ref.read(postControllerProvider.notifier),
  );
});

class NewsfeedRepository {
  final FirebaseFirestore _firestore;
  final PostController _postController;

  NewsfeedRepository({
    required FirebaseFirestore firestore,
    required PostController postController,
  })  : _firestore = firestore,
        _postController = postController;

  //REFERENCE ALL THE USERS
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);
  //REFERENCE ALL THE COMMUNITIES
  CollectionReference get _communities =>
      _firestore.collection(FirebaseConstants.communitiesCollection);
  //REFERENCE THE POSTS DATA
  CollectionReference get _posts =>
      _firestore.collection(FirebaseConstants.postsCollection);

  Future<List<PostDataModel>> getNewsfeedInitPosts({
    required List<String>? communityIds,
  }) async {
    if (communityIds == null || communityIds.isEmpty) {
      return [];
    }

    final List<PostDataModel> allPosts = [];

    for (String communityId in communityIds) {
      final querySnapshot = await _posts
          .where('communityId', isEqualTo: communityId)
          .where('status', isEqualTo: 'Approved')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      List<Post> posts = querySnapshot.docs
          .map((doc) => Post.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      for (var post in posts) {
        final postDataResult =
            await _postController.getPostDataByPostId(postId: post.id);
        postDataResult.fold(
          (l) => allPosts
              .add(PostDataModel(post: post, author: null, community: null)),
          (r) => allPosts.add(r!),
        );
      }
    }

    return allPosts;
  }

  Future<List<PostDataModel>> fetchMorePosts({
    required List<String> communityIds,
    required Timestamp? lastPostCreatedAt,
  }) async {
    try {
      if (communityIds.isEmpty) {
        return [];
      }

      final query = _posts
          .where('communityId', whereIn: communityIds)
          .where('status', isEqualTo: 'Approved')
          .orderBy('createdAt', descending: true)
          .startAfter([lastPostCreatedAt]).limit(10);

      final postsQuerySnapshot = await query.get();
      if (postsQuerySnapshot.docs.isEmpty) {
        return [];
      }

      List<PostDataModel> postDataList = [];

      List<Post> posts = postsQuerySnapshot.docs
          .map((doc) => Post.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      for (var post in posts) {
        final postDataResult =
            await _postController.getPostDataByPostId(postId: post.id);
        postDataResult.fold(
          (l) => postDataList
              .add(PostDataModel(post: post, author: null, community: null)),
          (r) => postDataList.add(r!),
        );
      }
      return postDataList;
    } catch (e) {
      return [];
    }
  }
}
