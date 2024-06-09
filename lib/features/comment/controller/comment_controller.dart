import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/features/comment/repository/comment_repository.dart';
import 'package:hash_balance/models/comment_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';

final getCommentsByPostProvider = StreamProvider.family((ref, String postId) {
  return ref
      .watch(commentControllerProvider.notifier)
      .getCommentsByPost(postId);
});

final commentControllerProvider =
    StateNotifierProvider<CommentController, bool>(
  (ref) => CommentController(
    commentRepository: ref.read(commentRepositoryProvider),
    ref: ref,
  ),
);

class CommentController extends StateNotifier<bool> {
  final CommentRepository _commentRepository;
  final Ref _ref;

  CommentController({
    required CommentRepository commentRepository,
    required Ref ref,
  })  : _commentRepository = commentRepository,
        _ref = ref,
        super(false);

  //COMMENT
  FutureString comment(
    UserModel user,
    Post post,
    String? content,
    File? image,
    File? video,
  ) async {
    state = true;
    try {
      final comment = Comment(
        uid: user.uid,
        postId: post.id,
        createdAt: Timestamp.now(),
        content: content,
        image: '',
        video: '',
        upvotes: ['empty'],
        downvotes: ['empty'],
        replies: ['empty'],
        upvoteCount: 0,
      );
      final result = await _commentRepository.comment(
        user,
        post,
        comment,
        content,
        image,
        video,
      );
      return result.fold(
        (l) => left((Failures(l.message))),
        (r) => right('Comment Was Successfully Done!'),
      );
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    } finally {
      state = false;
    }
  }

  //GET COMMENTS BY POSTS
  Stream<List<Comment>> getCommentsByPost(String postId) {
    state = true;
    try {
      return _commentRepository.getCommentsByPost(postId);
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    } finally {
      state = false;
    }
  }
}
