import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/post_share_model.dart';

final postShareRepositoryProvider = Provider((ref) {
  return PostShareRepository(firestore: ref.watch(firebaseFirestoreProvider));
});

class PostShareRepository {
  final FirebaseFirestore _firestore;

  PostShareRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  //REFERENCE ALL THE SHARE POSTS
  CollectionReference get _postShares =>
      _firestore.collection(FirebaseConstants.postShareCollection);
  //REFERENCE ALL THE POSTS
  CollectionReference get _posts =>
      _firestore.collection(FirebaseConstants.postsCollection);

  //SHARE A POST
  FutureVoid sharePost(PostShare postShare) async {
    try {
      await _postShares.doc(postShare.id).set(postShare.toMap());
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //FETCH THE NUMBER OF SHARE COUNT OF A POST
  Stream<int> getPostShareCount(String postId) {
    return _postShares
        .where('postId', isEqualTo: postId)
        .snapshots()
        .map((event) {
      return event.size;
    });
  }

// FETCH FRIENDS' SHARE POSTS
  Stream<List<Post>?> getFriendsSharePosts(List<String> friendUids) {
    return _postShares
        .where('uid', whereIn: friendUids)
        .snapshots()
        .asyncMap((event) async {
      if (event.docs.isEmpty) {
        return null;
      }

      List<String> postIds = event.docs.map((doc) {
        final docData = doc.data() as Map<String, dynamic>;
        return docData['postId'];
      }).toList() as List<String>;

      const int batchSize = 10;
      List<Post> posts = <Post>[];

      for (var i = 0; i < postIds.length; i += batchSize) {
        final batchPostIds = postIds.sublist(
          i,
          i + batchSize > postIds.length ? postIds.length : i + batchSize,
        );

        final postsDoc =
            await _posts.where('postId', whereIn: batchPostIds).get();

        if (postsDoc.docs.isNotEmpty) {
          for (final doc in postsDoc.docs) {
            final docData = doc.data() as Map<String, dynamic>;
            posts.add(Post.fromMap(docData));
          }
        }
      }

      return posts.isEmpty ? null : posts;
    });
  }
}
