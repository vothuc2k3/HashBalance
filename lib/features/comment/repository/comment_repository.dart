import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/common/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/providers/storage_repository_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/comment_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';

final commentRepositoryProvider = Provider((ref) {
  return CommentRepository(
    firestore: ref.read(firebaseFirestoreProvider),
    storageRepository: ref.read(storageRepositoryProvider),
  );
});

class CommentRepository {
  final FirebaseFirestore _firestore;
  final StorageRepository _storageRepository;
  final batch = FirebaseFirestore.instance.batch();

  CommentRepository({
    required FirebaseFirestore firestore,
    required StorageRepository storageRepository,
  })  : _firestore = firestore,
        _storageRepository = storageRepository;

  //COMMENT ON A POST
  FutureVoid comment(
    UserModel user,
    Post post,
    Comment comment,
    String? content,
    File? image,
    File? video,
  ) async {
    try {
      await _comments.doc().set(comment.toMap());
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //GET COMMENTS BY POST
  Stream<List<Comment>> getCommentsByPost(String postId) {
    try {
      return _comments
          .where(
            'postId',
            isEqualTo: postId,
          )
          .snapshots()
          .map(
        (event) {
          List<Comment> comments = [];
          for (var comment in event.docs) {
            final data = comment.data() as Map<String, dynamic>;
            final upvotes = (data['upvotes'] as List?)?.cast<String>() ?? [];
            final downvotes =
                (data['downvotes'] as List?)?.cast<String>() ?? [];
            final replies = (data['replies'] as List?)?.cast<String>() ?? [];
            comments.add(
              Comment(
                uid: data['id'] as String,
                postId: postId,
                createdAt: data['createdAt'] as Timestamp,
                upvotes: upvotes,
                downvotes: downvotes,
                replies: replies,
                upvoteCount: data['upvoteCount'],
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
  Stream<Comment> getTopComment(String postId) {
    try {
      return FirebaseFirestore.instance
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .orderBy('upvoteCount', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots()
          .map((event) {
        if (event.docs.isEmpty) {
          throw Exception("No comments found");
        }

        var doc = event.docs.first;
        final data = doc.data();

        final upvotes = (data['upvotes'] as List?)?.cast<String>() ?? [];
        final downvotes = (data['downvotes'] as List?)?.cast<String>() ?? [];
        final replies = (data['replies'] as List?)?.cast<String>() ?? [];

        return Comment(
          uid: data['id'] as String,
          postId: postId,
          createdAt: data['createdAt'] as Timestamp,
          upvotes: upvotes,
          downvotes: downvotes,
          replies: replies,
          upvoteCount: data['upvoteCount'] as int,
        );
      });
    } on FirebaseException catch (e) {
      throw Exception('FirebaseException: ${e.message}');
    } catch (e) {
      throw Exception('Exception: ${e.toString()}');
    }
  }

  //REFERENCE ALL THE COMMENTS
  CollectionReference get _comments =>
      _firestore.collection(FirebaseConstants.commentsCollection);
}
