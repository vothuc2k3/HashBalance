import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/models/post_model.dart';

final newsfeedRepositoryProvider = Provider((ref) {
  return NewsfeedRepository(firestore: ref.watch(firebaseFirestoreProvider));
});

class NewsfeedRepository {
  final FirebaseFirestore _firestore;

  NewsfeedRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  //GET THE COMMUNITIES BY CURRENT USER
  Stream<List<Post>> getJoinedCommunitiesPosts(String uid) {
    return _communityMembership
        .where('uid', isEqualTo: uid)
        .snapshots()
        .asyncMap((data) async {
      final communitiesId =
          data.docs.map((doc) => doc['communityId'] as String).toList();
      final List<Post> posts = [];
      for (var communityId in communitiesId) {
        final communityPosts =
            await _posts.where('communityId', isEqualTo: communityId).get();
        for (var postDoc in communityPosts.docs) {
          posts.add(
            Post.fromMap(postDoc.data() as Map<String, dynamic>),
          );
        }
      }
      return posts;
    });
  }

  //REFERENCE THE POSTS DATA
  CollectionReference get _posts =>
      _firestore.collection(FirebaseConstants.postsCollection);
  //REFERENCE THE COMMUNITIES DATA
  CollectionReference get _communityMembership =>
      _firestore.collection(FirebaseConstants.communityMembershipCollection);
}
