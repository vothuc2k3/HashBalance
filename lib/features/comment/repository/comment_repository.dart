import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/common/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/providers/storage_repository_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/comment_model.dart';

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
            final upvotes = List<String>.from(data['upvotes']);
            final downvotes = List<String>.from(data['downvotes']);
            comments.add(
              Comment(
                uid: data['uid'] as String,
                content: data['content'] as String,
                postId: postId,
                createdAt: data['createdAt'] as Timestamp,
                upvotes: upvotes,
                downvotes: downvotes,
                upvoteCount: data['upvoteCount'] as int,
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
            final upvotes = List<String>.from(data['upvotes']);
            final downvotes = List<String>.from(data['downvotes']);
            comments.add(
              Comment(
                uid: data['uid'] as String,
                content: data['content'] as String,
                postId: postId,
                createdAt: data['createdAt'] as Timestamp,
                upvotes: upvotes,
                downvotes: downvotes,
                upvoteCount: data['upvoteCount'] as int,
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

  //GET MOST RELEVANT COMMENTS BY POST
  Stream<List<Comment>> getRelevantCommentsByPost(String postId) {
    try {
      return _comments
          .where('postId', isEqualTo: postId)
          .orderBy('upvoteCount', descending: true)
          .snapshots()
          .map(
        (event) {
          List<Comment> comments = [];
          for (var comment in event.docs) {
            final data = comment.data() as Map<String, dynamic>;
            final upvotes = List<String>.from(data['upvotes']);
            final downvotes = List<String>.from(data['downvotes']);
            comments.add(
              Comment(
                uid: data['uid'] as String,
                content: data['content'] as String,
                postId: postId,
                createdAt: data['createdAt'] as Timestamp,
                upvotes: upvotes,
                downvotes: downvotes,
                upvoteCount: data['upvoteCount'] as int,
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

  //GET THE COMMENT WITH HIGHEST UPVOTES
  Stream<List<Comment>> getTopComment(String postId) {
    try {
      return _comments
          .where('postId', isEqualTo: postId)
          .orderBy('upvoteCount', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots()
          .map((event) {
        List<Comment> comments = [];
        for (var comment in event.docs) {
          final data = comment.data() as Map<String, dynamic>;
          final upvotes = (data['upvotes'] as List?)?.cast<String>() ?? [];
          final downvotes = (data['downvotes'] as List?)?.cast<String>() ?? [];
          comments.add(
            Comment(
              content: data['content'] as String,
              uid: data['uid'] as String,
              postId: postId,
              createdAt: data['createdAt'] as Timestamp,
              upvotes: upvotes,
              downvotes: downvotes,
              upvoteCount: data['upvoteCount'],
              id: data['id'] as String,
            ),
          );
        }
        return comments;
      });
    } on FirebaseException catch (e) {
      throw Exception('FirebaseException: ${e.message}');
    } catch (e) {
      throw Exception('Exception: ${e.toString()}');
    }
  }

  //GET COMMENT COUNT
  Stream<int> getCommentCount(String postId) {
    return _comments.where('postId', isEqualTo: postId).snapshots().map(
      (event) {
        return event.size;
      },
    );
  }

  //UPVOTE A COMMENT
  FutureVoid upvote(
      String commentId, String upvoteUid, String authorUid) async {
    final batch = FirebaseFirestore.instance.batch();
    try {
      final commentDoc = await _comments.doc(commentId).get();
      final data = commentDoc.data() as Map<String, dynamic>;
      var upvotes = List<String>.from(data['upvotes'] ?? <String>[]);
      var downvotes = List<String>.from(data['downvotes'] ?? <String>[]);
      var upvoteCount = data['upvoteCount'] as int;
      if (downvotes.contains(upvoteUid)) {
        downvotes.remove(upvoteUid);
        batch.update(_comments.doc(commentId), {
          'downvotes': downvotes,
        });
      }
      if (upvotes.contains(upvoteUid)) {
        upvotes.remove(upvoteUid);
        upvoteCount -= 1;
        batch.update(_comments.doc(commentId), {
          'upvotes': upvotes,
          'upvoteCount': upvoteCount,
        });
        batch.update(_users.doc(authorUid), {
          'activityPoint': FieldValue.increment(-1),
        });
      } else {
        upvotes.add(upvoteUid);
        upvoteCount += 1;
        batch.update(_comments.doc(commentId), {
          'upvotes': upvotes,
          'upvoteCount': upvoteCount,
        });
        batch.update(_users.doc(authorUid), {
          'activityPoint': FieldValue.increment(1),
        });
      }
      await batch.commit();
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //DOWNVOTE A COMMENT
  FutureVoid downvote(
      String commentId, String downvoteUid, String authorUid) async {
    final batch = FirebaseFirestore.instance.batch();
    try {
      final commentDoc = await _comments.doc(commentId).get();
      if (commentDoc.exists) {
        final data = commentDoc.data();
        final commentData = data as Map<String, dynamic>;
        var downvotes =
            List<String>.from(commentData['downvotes'] ?? <String>[]);
        var upvotes = List<String>.from(commentData['upvotes'] ?? <String>[]);
        var upvoteCount = commentData['upvoteCount'] as int;
        if (upvotes.contains(downvoteUid)) {
          upvotes.remove(downvoteUid);
          upvoteCount -= 1;
          batch.update(_comments.doc(commentId), {
            'upvotes': upvotes,
            'upvoteCount': upvoteCount,
          });
          batch.update(_users.doc(authorUid), {
            'activityPoint': FieldValue.increment(-1),
          });
        }
        if (downvotes.contains(downvoteUid)) {
          downvotes.remove(downvoteUid);
          batch.update(_comments.doc(commentId), {
            'downvotes': downvotes,
          });
        } else {
          downvotes.add(downvoteUid);
          batch.update(_comments.doc(commentId), {
            'downvotes': downvotes,
          });
        }
        await batch.commit();
        return right(null);
      } else {
        return left(Failures('Post not found'));
      }
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //CHECK IF THE USER UPVOTED THE POST
  Stream<bool> checkDidUpvote(String postId, String uid) {
    return _comments.doc(postId).snapshots().map((event) {
      final data = event.data() as Map<String, dynamic>;
      final upvotes = List<String>.from(data['upvotes']);
      if (upvotes.contains(uid)) {
        return true;
      } else {
        return false;
      }
    });
  }

  //CHECK IF THE USER DOWNVOTED THE COMMENT
  Stream<bool> checkDidDownvote(
    String postId,
    String uid,
  ) {
    return _comments.doc(postId).snapshots().map((event) {
      final data = event.data() as Map<String, dynamic>;
      final downvotes = List<String>.from(data['downvotes']);
      if (downvotes.contains(uid)) {
        return true;
      } else {
        return false;
      }
    });
  }

  //GET THE UPVOTE COUNTS OF THE COMMENT
  Stream<int> getUpvotes(String postId) {
    return _comments.doc(postId).snapshots().map((event) {
      final data = event.data() as Map<String, dynamic>;
      return List<String>.from(data['upvotes']).length - 1;
    });
  }

  //GET THE DOWNVOTE COUNTS OF THE COMMENT
  Stream<int> getDownvotes(String postId) {
    return _comments.doc(postId).snapshots().map((event) {
      final data = event.data() as Map<String, dynamic>;
      if (List<String>.from(data['downvotes']).isEmpty) {
        return 0;
      } else {
        return List<String>.from(data['downvotes']).length - 1;
      }
    });
  }

  //REFERENCE ALL THE COMMENTS
  CollectionReference get _comments =>
      _firestore.collection(FirebaseConstants.commentsCollection);
  //REFERENCE ALL THE USERS
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);
}
