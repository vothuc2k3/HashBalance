import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/models/post_vote_model.dart';
import 'package:hash_balance/models/post_model.dart';

final votePostRepositoryProvider = Provider((ref) {
  return VotePostRepository(firestore: ref.watch(firebaseFirestoreProvider));
});

class VotePostRepository {
  final FirebaseFirestore _firestore;

  VotePostRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  //REFERENCE ALL THE POST
  CollectionReference get _posts =>
      _firestore.collection(FirebaseConstants.postsCollection);

// VOTE THE POST
  Future<void> votePost(PostVote postVoteModel, Post post) async {
    final batch = _firestore.batch();
    try {
      final postVoteCollection =
          _posts.doc(post.id).collection(FirebaseConstants.postVoteCollection);
      final querySnapshot = await postVoteCollection
          .where('uid', isEqualTo: postVoteModel.uid)
          .get();

      if (querySnapshot.docs.isEmpty) {
        final postVoteRef = postVoteCollection.doc(postVoteModel.id);
        batch.set(postVoteRef, postVoteModel.toMap());
      } else {
        final data = querySnapshot.docs.first.data();
        final postVoteModelId = querySnapshot.docs.first.id;
        final isAlreadyUpvoted = data['isUpvoted'] as bool;
        final doWantToUpvote = postVoteModel.isUpvoted;

        if (doWantToUpvote == isAlreadyUpvoted) {
          batch.delete(postVoteCollection.doc(postVoteModelId));
        } else {
          batch.update(
              postVoteCollection.doc(postVoteModelId), postVoteModel.toMap());
        }
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw e.message!;
    } catch (e) {
      throw e.toString();
    }
  }
}
