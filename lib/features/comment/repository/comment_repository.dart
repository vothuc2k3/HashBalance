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

final commentRepositoryProvider = Provider((ref) {
  return CommentRepository(
    firestore: ref.read(firebaseFirestoreProvider),
    storageRepository: ref.read(storageRepositoryProvider),
  );
});

class CommentRepository {
  final FirebaseFirestore _firestore;
  // final StorageRepository _storageRepository;

  CommentRepository({
    required FirebaseFirestore firestore,
    required StorageRepository storageRepository,
  }) : _firestore = firestore;
  // _storageRepository = storageRepository

  //COMMENT ON A POST
  FutureVoid comment(
    Comment comment,
  ) async {
    try {
      await _comments.doc(comment.id).set(comment.toMap());
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //VOTE COMMENT
  Future<void> voteComment(CommentVote commentVoteModel) async {
    try {
      final querySnapshot = await _commentVotes
          .where('commentId', isEqualTo: commentVoteModel.commentId)
          .where('uid', isEqualTo: commentVoteModel.uid)
          .get();
      if (querySnapshot.docs.isEmpty) {
        await _commentVotes
            .doc(commentVoteModel.id)
            .set(commentVoteModel.toMap());
      } else {
        final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
        final commentVoteModelId = data['id'] as String;
        final commentVoteModelCopy =
            commentVoteModel.copyWith(id: commentVoteModelId);
        final isAlreadyUpvoted = data['isUpvoted'] as bool;
        final doWantToUpvote = commentVoteModelCopy.isUpvoted;
        if (doWantToUpvote == isAlreadyUpvoted) {
          await _commentVotes.doc(commentVoteModelId).delete();
        } else {
          await _commentVotes
              .doc(commentVoteModelId)
              .update(commentVoteModelCopy.toMap());
        }
      }
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  //GET COMMENT VOTE COUNT
  Stream<Map<String, int>> getCommentVoteCount(String commentId, String uid) {
    return _commentVotes
        .where('commentId', isEqualTo: commentId)
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((event) {
      int upvoteCount = 0;
      int downvoteCount = 0;
      for (var doc in event.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['isUpvoted'] == true) {
          upvoteCount++;
        } else {
          downvoteCount++;
        }
      }
      return {
        'upvotes': upvoteCount,
        'downvotes': downvoteCount,
      };
    });
  }

  //GET NEWEST COMMENTS BY POST
  Stream<List<Comment>> getNewestCommentsByPost(String postId) {
    try {
      return _comments
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
        (event) {
          List<Comment> comments = [];
          for (var comment in event.docs) {
            final data = comment.data() as Map<String, dynamic>;
            comments.add(
              Comment(
                uid: data['uid'] as String,
                content: data['content'] as String,
                postId: postId,
                createdAt: data['createdAt'] as Timestamp,
                id: data['id'] as String,
              ),
            );
          }
          return comments;
        },
      );
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  //GET OLDEST COMMENTS BY POST
  Stream<List<Comment>> getOldestCommentsByPost(String postId) {
    try {
      return _comments
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map(
        (event) {
          List<Comment> comments = [];
          for (var comment in event.docs) {
            final data = comment.data() as Map<String, dynamic>;
            comments.add(
              Comment(
                uid: data['uid'] as String,
                content: data['content'] as String,
                postId: postId,
                createdAt: data['createdAt'] as Timestamp,
                id: data['id'] as String,
              ),
            );
          }
          return comments;
        },
      );
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  // //GET MOST RELEVANT COMMENTS BY POST
  Stream<List<Comment>> getRelevantCommentsByPost(String postId) {
    try {
      return _commentVotes
          .where('postId', isEqualTo: postId)
          .snapshots()
          .asyncMap((snapshot) async {
        Map<String, int> commentUpvotes = {};

        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final commentId = data['commentId'] as String;
          final isUpvoted = data['isUpvoted'] as bool;

          if (isUpvoted) {
            if (commentUpvotes.containsKey(commentId)) {
              commentUpvotes[commentId] = commentUpvotes[commentId]! + 1;
            } else {
              commentUpvotes[commentId] = 1;
            }
          }
        }

        if (commentUpvotes.isEmpty) {
          return [];
        }

        List<Comment> comments = [];
        for (var commentId in commentUpvotes.keys) {
          final commentDoc = await _comments.doc(commentId).get();
          final commentData = commentDoc.data() as Map<String, dynamic>;
          final comment = Comment.fromMap(commentData);
          comments.add(comment);
        }

        comments.sort(
            (a, b) => commentUpvotes[b.id]!.compareTo(commentUpvotes[a.id]!));

        return comments;
      });
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  //GET 1 TOP COMMENT
  Stream<Comment?> getTopComment(String postId) {
    return _commentVotes
        .where('postId', isEqualTo: postId)
        .snapshots()
        .asyncMap(
      (snapshot) async {
        Map<String, int> commentUpvotes = {};
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final commentId = data['commentId'] as String;
          final isUpvoted = data['isUpvoted'] as bool;

          if (isUpvoted) {
            if (commentUpvotes.containsKey(commentId)) {
              commentUpvotes[commentId] = commentUpvotes[commentId]! + 1;
            } else {
              commentUpvotes[commentId] = 1;
            }
          }
        }
        if (commentUpvotes.isEmpty) {
          return null;
        }
        final topCommentId = commentUpvotes.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
        final commentDoc = await _comments.doc(topCommentId).get();
        final topCommentData = commentDoc.data() as Map<String, dynamic>;
        return Comment.fromMap(topCommentData);
      },
    ).where((comment) => comment != null);
  }

  //GET TOTAL COMMENTS COUNT OF A COMMENT
  Stream<int> getPostCommentCount(String postId) {
    return _comments
        .where('postId', isEqualTo: postId)
        .snapshots()
        .map((event) {
      return event.size;
    });
  }

  Stream<bool?> getCommentVoteStatus(String commentId, String uid) {
    try {
      return _commentVotes
          .where('commentId', isEqualTo: commentId)
          .where('uid', isEqualTo: uid)
          .snapshots()
          .map((event) {
        if (event.docs.isEmpty) {
          return null;
        }
        bool isUpvoted = true;
        for (var doc in event.docs) {
          final data = doc.data() as Map<String, dynamic>;
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

  //REFERENCE ALL THE COMMENTS
  CollectionReference get _comments =>
      _firestore.collection(FirebaseConstants.commentsCollection);

  //REFERENCE ALL THE COMMENT VOTES
  CollectionReference get _commentVotes =>
      _firestore.collection(FirebaseConstants.commentVoteCollection);
}
