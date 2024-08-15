import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:tuple/tuple.dart';

import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/comment/repository/comment_repository.dart';
import 'package:hash_balance/models/comment_model.dart';
import 'package:hash_balance/models/comment_vote_model.dart';
import 'package:hash_balance/models/post_model.dart';

final getCommentVoteStatusProvider =
    StreamProvider.family<bool?, Tuple2<Post, Comment>>((ref, tuple) {
  return ref
      .watch(commentControllerProvider.notifier)
      .getCommentVoteStatus(tuple.item1, tuple.item2);
});

final getCommentVoteCountProvider =
    StreamProvider.family<Map<String, int>, Tuple2<Post, Comment>>(
        (ref, tuple) {
  return ref
      .watch(commentControllerProvider.notifier)
      .getCommentVoteCount(tuple.item1, tuple.item2);
});

final getRelevantCommentsByPostProvider =
    StreamProvider.family((ref, Post post) {
  return ref
      .read(commentControllerProvider.notifier)
      .getRelevantCommentsByPost(post);
});

final getPostCommentCountProvider = StreamProvider.family((ref, String postId) {
  return ref
      .read(commentControllerProvider.notifier)
      .getPostCommentCount(postId);
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
    Post post,
    String? content,
  ) async {
    state = true;
    try {
      final user = _ref.read(userProvider);
      final comment = Comment(
        uid: user!.uid,
        postId: post.id,
        createdAt: Timestamp.now(),
        content: content,
        id: await generateRandomId(),
        upvoteCount: 0,
        downvoteCount: 0,
      );
      final result = await _commentRepository.comment(comment, post);
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

  //VOTE THE COMMENT
  FutureVoid voteComment(Comment comment, Post post, bool userVote) async {
    try {
      final currentUser = _ref.read(userProvider)!;
      final commentVoteModel = CommentVote(
        id: await generateRandomId(),
        commentId: comment.id,
        uid: currentUser.uid,
        isUpvoted: userVote,
        createdAt: Timestamp.now(),
      );

      await _commentRepository.voteComment(commentVoteModel, comment, post);
      state = false;
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    } 
  }

  Stream<Map<String, int>> getCommentVoteCount(Post post, Comment comment) {
    return _commentRepository.getCommentVoteCount(post, comment.id);
  }

  //GET POST COMMENT COUNT
  Stream<int> getPostCommentCount(String postId) {
    try {
      return _commentRepository.getPostCommentCount(postId);
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  Stream<bool?> getCommentVoteStatus(Post post, Comment comment) {
    try {
      final uid = _ref.read(userProvider)!.uid;
      return _commentRepository.getCommentVoteStatus(post.id, comment.id, uid);
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  // GET OLDEST COMMENTS BY POSTS
  Stream<List<Comment>> getRelevantCommentsByPost(Post post) {
    try {
      return _commentRepository.getRelevantCommentsByPost(post);
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }
}
