import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/constants/firebase_constants.dart';
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
        .where(
          'uid',
          isEqualTo: uid,
        )
        .snapshots()
        .asyncMap((data) async {
      final communityNames =
          data.docs.map((doc) => doc['communityName'] as String).toList();
      final List<Post> posts = [];
      for (var communityName in communityNames) {
        final communityPosts = await _posts
            .where(
              'communityName',
              isEqualTo: communityName,
            )
            .get();
        for (var postDoc in communityPosts.docs) {
          var content = postDoc['content'] ?? '';
          var image = postDoc['image'] ?? '';
          var video = postDoc['video'] ?? '';
          posts.add(
            Post(
              video: video as String,
              image: image as String,
              content: content as String,
              communityName: postDoc['communityName'] as String,
              uid: postDoc['uid'] as String,
              createdAt: postDoc['createdAt'] as Timestamp,
              id: postDoc['id'] as String,
            ),
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
