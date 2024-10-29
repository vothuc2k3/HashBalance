import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';
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
  //REFERENCE THE POSTS DATA
  CollectionReference get _posts =>
      _firestore.collection(FirebaseConstants.postsCollection);

  Stream<List<PostDataModel>> getNewsfeedInitPosts({
    required List<String>? communityIds,
  }) {
    if (communityIds == null) {
      return Stream.value([]);
    }
    return _posts
        .where('communityId', whereIn: communityIds)
        .where('status', isEqualTo: 'Approved')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .asyncMap((postsQuery) async {
      final List<PostDataModel> postDataList = [];

      List<Post> posts = postsQuery.docs
          .map((doc) => Post.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      for (var post in posts) {
        final authorDoc = await _users.doc(post.uid).get();
        final author =
            UserModel.fromMap(authorDoc.data() as Map<String, dynamic>);

        final communityDoc = await _communities.doc(post.communityId).get();
        final community =
            Community.fromMap(communityDoc.data() as Map<String, dynamic>);

        postDataList.add(
          PostDataModel(post: post, author: author, community: community),
        );
      }

      return postDataList;
    });
  }
}
