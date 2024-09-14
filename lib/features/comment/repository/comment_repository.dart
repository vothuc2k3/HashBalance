import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/comment_model.dart';
import 'package:hash_balance/models/conbined_models/comment_data_model.dart';
import 'package:hash_balance/models/user_model.dart';

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

  FutureVoid deleteComment(String commentId) async {
    try {
      await _comments.doc(commentId).delete();
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  FutureVoid clearPostComments(String postId) async {
    try {
      await _comments.where('postId', isEqualTo: postId).get().then((value) {
        for (var doc in value.docs) {
          doc.reference.delete();
        }
      });
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //FETCH ALL COMMENTS OF A POST
  Stream<List<CommentDataModel>?> getPostComments(String postId) {
    return _comments
        .where('postId', isEqualTo: postId)
        .where('parentCommentId', isEqualTo: '')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap(
      (event) async {
        if (event.docs.isEmpty) {
          return null;
        } else {
          List<CommentDataModel> commentDataList = <CommentDataModel>[];

          for (var doc in event.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final comment = CommentModel.fromMap(data);
            final authorDoc = await _firestore
                .collection(FirebaseConstants.usersCollection)
                .doc(comment.uid)
                .get();
            final authorData = authorDoc.data() as Map<String, dynamic>;
            final author = UserModel.fromMap(authorData);
            commentDataList.add(
              CommentDataModel(
                comment: comment,
                author: author,
              ),
            );
          }

          return commentDataList;
        }
      },
    );
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
