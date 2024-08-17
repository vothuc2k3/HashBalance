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
    firestore: ref.watch(firebaseFirestoreProvider),
    storageRepository: ref.watch(storageRepositoryProvider),
  );
});

class CommentRepository {
  final FirebaseFirestore _firestore;

  CommentRepository({
    required FirebaseFirestore firestore,
    required StorageRepository storageRepository,
  }) : _firestore = firestore;

  //REFERENCE ALL THE COMMENTS
  CollectionReference get _comments =>
      _firestore.collection(FirebaseConstants.commentsCollection);
  //REFERENCE ALL THE POSTS
  CollectionReference get _posts =>
      _firestore.collection(FirebaseConstants.postsCollection);

//COMMENT ON A POST
  FutureVoid comment(Comment comment) async {
    try {
      await _comments.doc(comment.id).set(comment.toMap());
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

// VOTE COMMENT
  Future<void> voteComment(
    CommentVote commentVoteModel,
    Comment comment,
  ) async {
    final batch = _firestore.batch();
    try {
      final commentVoteCollectionRef = _comments
          .doc(comment.id)
          .collection(FirebaseConstants.commentVoteCollection);

      final commentVoteRef = commentVoteCollectionRef.doc(commentVoteModel.uid);

      final commentVoteDoc = await commentVoteRef.get();

      if (!commentVoteDoc.exists) {
        batch.set(commentVoteRef, commentVoteModel.toMap());
        if (commentVoteModel.isUpvoted) {
          batch.update(_comments.doc(comment.id), {
            'upvoteCount': FieldValue.increment(1),
          });
        } else {
          batch.update(_comments.doc(comment.id), {
            'downvoteCount': FieldValue.increment(1),
          });
        }
      } else {
        final data = commentVoteDoc.data() as Map<String, dynamic>;
        final isAlreadyUpvoted = data['isUpvoted'] as bool;
        final doWantToUpvote = commentVoteModel.isUpvoted;

        if (doWantToUpvote == isAlreadyUpvoted) {
          batch.delete(commentVoteRef);
          if (doWantToUpvote) {
            batch.update(_comments.doc(comment.id), {
              'upvoteCount': FieldValue.increment(-1),
            });
          } else {
            batch.update(_comments.doc(comment.id), {
              'downvoteCount': FieldValue.increment(-1),
            });
          }
        } else {
          batch.update(commentVoteRef, commentVoteModel.toMap());
          if (doWantToUpvote) {
            batch.update(_comments.doc(comment.id), {
              'upvoteCount': FieldValue.increment(1),
              'downvoteCount': FieldValue.increment(-1),
            });
          } else {
            batch.update(_comments.doc(comment.id), {
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

  //GET COMMENT VOTE COUNT
  Stream<Map<String, int>> getCommentVoteCount(String commentId) {
    return _comments.doc(commentId).snapshots().map(
      (event) {
        final data = event.data() as Map<String, dynamic>?;
        if (data != null) {
          final upvoteCount = data['upvoteCount'] ?? 0;
          final downvoteCount = data['downvoteCount'] ?? 0;
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
      },
    );
  }

// GET RELEVANT COMMENTS BY POST
  Stream<List<Comment>> getRelevantCommentsByPost(Post post) {
    try {
      return _comments
          .where('postId', isEqualTo: post.id)
          .snapshots()
          .map((snapshot) {
        List<Comment> comments = [];
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final comment = Comment.fromMap(data as Map<String, dynamic>);
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
    return _posts.doc(postId).snapshots().map((event) {
      final data = event.data() as Map<String, dynamic>;
      return data['commentCount'] ?? 0;
    });
  }

  // CHECK VOTE STATUS OF A USER TOWARDS A COMMENT
  Stream<bool?> getCommentVoteStatus(String commentId, String uid) {
    try {
      return _comments
          .doc(commentId)
          .collection(FirebaseConstants.commentVoteCollection)
          .doc(uid)
          .snapshots()
          .map((event) {
        if (event.exists) {
          return null;
        } else {
          return event.data()!['isUpvoted'];
        }
      });
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  //FETCH ALL COMMENTS OF A POST
  Stream<List<Comment>?> getPostComments(String postId) {
    try {
      return _comments.where('postId', isEqualTo: postId).snapshots().map(
        (event) {
          if (event.docs.isEmpty) {
            return null;
          } else {
            List<Comment> comments = <Comment>[];
            for (var doc in event.docs) {
              final data = doc.data() as Map<String, dynamic>;
              comments.add(Comment.fromMap(data));
            }
            return comments;
          }
        },
      );
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  //CHECK IF THE USER HAS UPVOTED THE POST OR NOT
  Future<bool?> fetchVoteCommentStatus(String commentId, String uid) async {
    final doc = await _comments
        .doc(commentId)
        .collection(FirebaseConstants.commentVoteCollection)
        .doc(uid)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      return data['isUpvoted'];
    }
    return null;
  }
}
