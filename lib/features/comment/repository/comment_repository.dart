import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/common/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/providers/storage_repository_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/comment_model.dart';
import 'package:hash_balance/models/comment_vote_model.dart';
import 'package:hash_balance/models/post_model.dart';

final commentRepositoryProvider = Provider((ref) {
  return CommentRepository(
    firestore: ref.read(firebaseFirestoreProvider),
    storageRepository: ref.read(storageRepositoryProvider),
  );
});

class CommentRepository {
  final FirebaseFirestore _firestore;

  CommentRepository({
    required FirebaseFirestore firestore,
    required StorageRepository storageRepository,
  }) : _firestore = firestore;

  //REFERENCE ALL THE POST VOTES
  CollectionReference get _posts =>
      _firestore.collection(FirebaseConstants.postsCollection);

  //COMMENT ON A POST
  FutureVoid comment(Comment comment, Post post) async {
    try {
      await _posts
          .doc(post.id)
          .collection(FirebaseConstants.commentsCollection)
          .doc(comment.id)
          .set(comment.toMap());
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

// VOTE COMMENT
  Future<void> voteComment(
      CommentVote commentVoteModel, Comment comment, Post post) async {
    final batch = _firestore.batch();
    try {
      final commentVoteCollectionRef = _posts
          .doc(post.id)
          .collection(FirebaseConstants.commentsCollection)
          .doc(comment.id)
          .collection(FirebaseConstants.commentVoteCollection);

      final querySnapshot = await commentVoteCollectionRef
          .where('commentId', isEqualTo: commentVoteModel.commentId)
          .where('uid', isEqualTo: commentVoteModel.uid)
          .get();

      if (querySnapshot.docs.isEmpty) {
        final commentVoteRef =
            commentVoteCollectionRef.doc(commentVoteModel.id);
        batch.set(commentVoteRef, commentVoteModel.toMap());
        if (commentVoteModel.isUpvoted) {
          batch.update(
              _posts
                  .doc(post.id)
                  .collection(FirebaseConstants.commentsCollection)
                  .doc(comment.id),
              {
                'upvoteCount': FieldValue.increment(1),
              });
        } else {
          batch.update(
              _posts
                  .doc(post.id)
                  .collection(FirebaseConstants.commentsCollection)
                  .doc(comment.id),
              {
                'downvoteCount': FieldValue.increment(1),
              });
        }
      } else {
        final data = querySnapshot.docs.first.data();
        final commentVoteModelId = querySnapshot.docs.first.id;
        final isAlreadyUpvoted = data['isUpvoted'] as bool;
        final doWantToUpvote = commentVoteModel.isUpvoted;

        if (doWantToUpvote == isAlreadyUpvoted) {
          batch.delete(commentVoteCollectionRef.doc(commentVoteModelId));
          if (doWantToUpvote) {
            batch.update(
                _posts
                    .doc(post.id)
                    .collection(FirebaseConstants.commentsCollection)
                    .doc(comment.id),
                {
                  'upvoteCount': FieldValue.increment(-1),
                });
          } else {
            batch.update(
                _posts
                    .doc(post.id)
                    .collection(FirebaseConstants.commentsCollection)
                    .doc(comment.id),
                {
                  'downvoteCount': FieldValue.increment(-1),
                });
          }
        } else {
          batch.update(commentVoteCollectionRef.doc(commentVoteModelId),
              commentVoteModel.toMap());
          if (doWantToUpvote) {
            batch.update(
                _posts
                    .doc(post.id)
                    .collection(FirebaseConstants.commentsCollection)
                    .doc(comment.id),
                {
                  'upvoteCount': FieldValue.increment(1),
                  'downvoteCount': FieldValue.increment(-1),
                });
          } else {
            batch.update(
                _posts
                    .doc(post.id)
                    .collection(FirebaseConstants.commentsCollection)
                    .doc(comment.id),
                {
                  'upvoteCount': FieldValue.increment(-1),
                  'downvoteCount': FieldValue.increment(1),
                });
          }
        }
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

// GET COMMENT VOTE COUNT
  Stream<Map<String, int>> getCommentVoteCount(Post post, String commentId) {
    return _posts
        .doc(post.id)
        .collection(FirebaseConstants.commentsCollection)
        .doc(commentId)
        .snapshots()
        .map((event) {
      if (event.data() != null) {
        final data = event.data()!;
        final upvoteCount = data['upvoteCount'];
        final downvoteCount = data['downvoteCount'];
        return {
          'upvotes': upvoteCount,
          'downvotes': downvoteCount,
        };
      } else {
        return {
          'upvotes': 0,
          'downvotes': 0,
        };
      }
    });
  }

// GET RELEVANT COMMENTS BY POST
  Stream<List<Comment>> getRelevantCommentsByPost(Post post) {
    try {
      return _posts
          .doc(post.id)
          .collection(FirebaseConstants.commentsCollection)
          .snapshots()
          .map((snapshot) {
        List<Comment> comments = [];
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final comment = Comment.fromMap(data);
          comments.add(comment);
        }

        comments.sort((a, b) => b.upvoteCount.compareTo(a.upvoteCount));

        return comments;
      });
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

// GET TOTAL COMMENTS COUNT OF A POST
  Stream<int> getPostCommentCount(String postId) {
    return _posts
        .doc(postId)
        .collection(FirebaseConstants.commentsCollection)
        .snapshots()
        .map((event) {
      return event.size;
    });
  }

// CHECK VOTE STATUS OF A USER TOWARDS A COMMENT
  Stream<bool?> getCommentVoteStatus(
      String postId, String commentId, String uid) {
    try {
      return _posts
          .doc(postId)
          .collection(FirebaseConstants.commentsCollection)
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
}
