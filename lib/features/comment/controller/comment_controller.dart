import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/comment/repository/comment_repository.dart';
import 'package:hash_balance/models/comment_model.dart';
import 'package:hash_balance/models/comment_vote_model.dart';
import 'package:hash_balance/models/post_model.dart';

final getPostCommentsProvider = StreamProvider.family((ref, String postId) {
  return ref.read(commentControllerProvider.notifier).getPostComments(postId);
});

final getCommentVoteStatusProvider =
    StreamProvider.family((ref, String commentId) {
  return ref
      .watch(commentControllerProvider.notifier)
      .getCommentVoteStatus(commentId);
});

final getCommentVoteCountProvider =
    StreamProvider.family((ref, String commentId) {
  return ref
      .watch(commentControllerProvider.notifier)
      .getCommentVoteCount(commentId);
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
    commentRepository: ref.watch(commentRepositoryProvider),
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
  FutureVoid comment(
    Post post,
    String? content,
  ) async {
    try {
      final user = _ref.watch(userProvider);
      final comment = Comment(
        uid: user!.uid,
        postId: post.id,
        createdAt: Timestamp.now(),
        content: content,
        id: await generateRandomId(),
        parentCommentId: '',
        upvoteCount: 0,
        downvoteCount: 0,
      );
      final result = await _commentRepository.comment(comment);
      return result.fold(
        (l) => left((Failures(l.message))),
        (r) => right(null),
      );
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //VOTE THE COMMENT
  FutureVoid voteComment(Comment comment, bool userVote) async {
    try {
      final currentUser = _ref.read(userProvider)!;
      final commentVoteModel = CommentVote(
        commentId: comment.id,
        uid: currentUser.uid,
        isUpvoted: userVote,
        createdAt: Timestamp.now(),
      );

      await _commentRepository.voteComment(
        commentVoteModel,
        comment,
      );
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<Map<String, int>> getCommentVoteCount(String commentId) {
    return _commentRepository.getCommentVoteCount(commentId);
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

  Stream<bool?> getCommentVoteStatus(String commentId) {
    try {
      final currentUser = _ref.watch(userProvider)!;
      return _commentRepository.getCommentVoteStatus(
          commentId, currentUser.uid);
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

  //FETCH ALL COMMENTS OF A POST
  Stream<List<Comment>?> getPostComments(String postId) {
    try {
      return _commentRepository.getPostComments(postId);
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  Future<bool?> fetchVoteCommentStatus(String commentId) async {
    final currentUser = _ref.watch(userProvider)!;
    return await _commentRepository.fetchVoteCommentStatus(
        commentId, currentUser.uid);
  }
}
