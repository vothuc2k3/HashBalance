import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';
import 'package:hash_balance/models/user_model.dart';

final searchRepositoryProvider = Provider(
  (ref) {
    return SearchRepository(
      firestore: ref.read(firebaseFirestoreProvider),
      postController: ref.read(postControllerProvider.notifier),
    );
  },
);

class SearchRepository {
  final FirebaseFirestore _firestore;
  final PostController _postController;
  SearchRepository({
    required FirebaseFirestore firestore,
    required PostController postController,
  })  : _firestore = firestore,
        _postController = postController;

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty || !query.startsWith('#')) {
      return [];
    }

    if (query == '#') {
      return [];
    }

    String userQuery = query.substring(1);

    try {
      final querySnapshot = await _user
          .where('name', isGreaterThanOrEqualTo: userQuery)
          .where('name', isLessThanOrEqualTo: '$userQuery\uf8ff')
          .limit(50)
          .get();

      final userList = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromMap(data);
      }).toList();

      final fuse = Fuzzy<UserModel>(
        userList,
        options: FuzzyOptions(
          keys: [
            WeightedKey<UserModel>(
              getter: (user) => user.name,
              weight: 1,
              name: 'name',
            ),
          ],
        ),
      );

      final results = fuse.search(userQuery);

      return results.map((result) => result.item).toList();
    } catch (error) {
      return [];
    }
  }

  Future<List<Community>> searchCommunities(String query) async {
    if (query.isEmpty || !query.startsWith('#=')) {
      return [];
    }

    if (query == '#=') {
      return [];
    }

    String communityQuery = query.substring(2);

    try {
      final querySnapshot = await _communities
          .where('name', isGreaterThanOrEqualTo: communityQuery)
          .where('name', isLessThanOrEqualTo: '$communityQuery\uf8ff')
          .where('type', isNotEqualTo: 'Private')
          .limit(50)
          .get();

      final communityList = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Community.fromMap(data);
      }).toList();

      final fuse = Fuzzy<Community>(
        communityList,
        options: FuzzyOptions(
          keys: [
            WeightedKey<Community>(
              getter: (community) => community.name,
              weight: 1,
              name: 'name',
            ),
          ],
        ),
      );

      final results = fuse.search(communityQuery);

      return results.map((result) => result.item).toList();
    } catch (error) {
      return [];
    }
  }

  Future<List<PostDataModel>> searchPosts(String query) async {
    if (query.isEmpty || query == '=') {
      return [];
    }

    try {
      final querySnapshot = await _posts.get();

      List<PostDataModel> postDataList = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final content = data['content'] as String;

        if (content.contains(query.substring(1))) {
          final result =
              await _postController.getPostDataByPostId(postId: doc.id);
          result.fold(
            (failure) {},
            (postData) {
              if (postData != null) {
                postDataList.add(postData);
              }
            },
          );
        }
      }
      return postDataList;
    } catch (error) {
      return [];
    }
  }

  CollectionReference get _communities =>
      _firestore.collection(FirebaseConstants.communitiesCollection);
  CollectionReference get _user =>
      _firestore.collection(FirebaseConstants.usersCollection);
  CollectionReference get _posts =>
      _firestore.collection(FirebaseConstants.postsCollection);
}
