import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
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
  Future<Either<Failures, void>> votePost(
      PostVote postVoteModel, Post post) async {
    final batch = _firestore.batch();
    try {
      final ids = postVoteModel.id;
      final postVoteCollection =
          _posts.doc(post.id).collection(FirebaseConstants.postVoteCollection);
      final querySnapshot = await postVoteCollection.doc(ids).get();

      if (!querySnapshot.exists) {
        final postVoteRef = postVoteCollection.doc(ids);
        batch.set(postVoteRef, postVoteModel.toMap());
      } else {
        final data = querySnapshot.data() as Map<String, dynamic>;
        final isAlreadyUpvoted = data['isUpvoted'] as bool;
        final doWantToUpvote = postVoteModel.isUpvoted;

        if (doWantToUpvote == isAlreadyUpvoted) {
          batch.delete(postVoteCollection.doc(ids));
        } else {
          batch.update(postVoteCollection.doc(ids), postVoteModel.toMap());
        }
      }
      await batch.commit();
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }
}
