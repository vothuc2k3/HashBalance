import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/models/comment_vote.dart';

final voteCommentRepositoryProvider = Provider((ref) {
  return VoteCommentRepository(firestore: ref.watch(firebaseFirestoreProvider));
});

class VoteCommentRepository {
  final FirebaseFirestore _firestore;

  const VoteCommentRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  //REFERENCE ALL THE COMMENTS
  CollectionReference get _comments =>
      _firestore.collection(FirebaseConstants.commentsCollection);

  // VOTE THE COMMENT
  Future<void> voteComment(
      CommentVote commentVoteModel, String commentId) async {
    final batch = _firestore.batch();
    try {
      final ids = commentVoteModel.id;
      final commentVoteCollection = _comments
          .doc(commentId)
          .collection(FirebaseConstants.commentVoteCollection);
      final querySnapshot = await commentVoteCollection.doc(ids).get();

      if (!querySnapshot.exists) {
        final commentVoteRef = commentVoteCollection.doc(ids);
        batch.set(commentVoteRef, commentVoteModel.toMap());
      } else {
        final data = querySnapshot.data() as Map<String, dynamic>;
        final isAlreadyUpvoted = data['isUpvoted'] as bool;
        final doWantToUpvote = commentVoteModel.isUpvoted;

        if (doWantToUpvote == isAlreadyUpvoted) {
          batch.delete(commentVoteCollection.doc(ids));
        } else {
          batch.update(
              commentVoteCollection.doc(ids), commentVoteModel.toMap());
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
