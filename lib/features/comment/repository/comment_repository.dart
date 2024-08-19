import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/common/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/comment_model.dart';
import 'package:hash_balance/models/comment_vote.dart';

final commentRepositoryProvider = Provider((ref) {
  return CommentRepository(firestore: ref.watch(firebaseFirestoreProvider));
});

class CommentRepository {
  final FirebaseFirestore _firestore;

  CommentRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  //REFERENCE ALL THE COMMENTS
  CollectionReference get _comments =>
      _firestore.collection(FirebaseConstants.commentsCollection);

//COMMENT ON A POST
  FutureVoid comment(CommentModel comment) async {
    try {
      await _comments.doc(comment.id).set(comment.toMap());
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //FETCH ALL COMMENTS OF A POST
  Stream<List<CommentModel>?> getPostComments(String postId) {
    return _comments
        .where('postId', isEqualTo: postId)
        .where('parentCommentId', isEqualTo: '')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
      (event) {
        if (event.docs.isEmpty) {
          return null;
        } else {
          List<CommentModel> comments = <CommentModel>[];
          for (var doc in event.docs) {
            final data = doc.data() as Map<String, dynamic>;
            comments.add(CommentModel.fromMap(data));
          }
          return comments;
        }
      },
    );
  }

// VOTE THE COMMENT
  FutureVoid voteComment(CommentVote commentVote) async {
    final batch = _firestore.batch();
    try {
      final commentVoteRef = _comments
          .doc(commentVote.commentId)
          .collection(FirebaseConstants.commentVoteCollection)
          .doc(commentVote.uid);

      final commentVoteDoc = await commentVoteRef.get();

      if (!commentVoteDoc.exists) {
        batch.set(commentVoteRef, commentVote.toMap());
      } else {
        final currentVote = CommentVote.fromMap(commentVoteDoc.data()!);

        if (currentVote.isUpvoted == commentVote.isUpvoted) {
          batch.delete(commentVoteRef);
        } else {
          batch.update(commentVoteRef, commentVote.toMap());
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

  Stream<bool?> getCommentVoteStatus(String commentId, String uid) {
    try {
      return _comments
          .doc(commentId)
          .collection(FirebaseConstants.commentVoteCollection)
          .where('uid', isEqualTo: uid)
          .snapshots()
          .map((event) {
        if (event.docs.isEmpty) {
          return null;
        }
        bool isUpvoted = true;
        for (var doc in event.docs) {
          final data = doc.data();
          isUpvoted = data['isUpvoted'];
          break;
        }
        return isUpvoted;
      });
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  Stream<Map<String, int>> getCommentVoteCount(String commentId) {
    return _comments
        .doc(commentId)
        .collection(FirebaseConstants.commentVoteCollection)
        .snapshots()
        .map((event) {
      int upvoteCount = 0;
      int downvoteCount = 0;
      for (var doc in event.docs) {
        final data = doc.data();
        if (data['isUpvoted'] == true) {
          upvoteCount++;
        } else if (data['isUpvoted'] == false) {
          downvoteCount++;
        }
      }
      return {
        'upvotes': upvoteCount,
        'downvotes': downvoteCount,
      };
    });
  }
}
