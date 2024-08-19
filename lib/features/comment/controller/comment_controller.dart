import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/comment/repository/comment_repository.dart';
import 'package:hash_balance/models/comment_model.dart';
import 'package:hash_balance/models/comment_vote.dart';
import 'package:hash_balance/models/post_model.dart';

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

final getPostCommentsProvider = StreamProvider.family((ref, String postId) {
  return ref.watch(commentControllerProvider.notifier).getPostComments(postId);
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
      final user = _ref.watch(userProvider)!;
      final comment = CommentModel(
        uid: user.uid,
        postId: post.id,
        createdAt: Timestamp.now(),
        content: content,
        id: await generateRandomId(),
        parentCommentId: '',
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

  //FETCH ALL COMMENTS OF A POST
  Stream<List<CommentModel>?> getPostComments(String postId) {
    return _commentRepository.getPostComments(postId);
  }

  //VOTE THE COMMENT
  FutureVoid voteComment(String commentId, bool isUpvoted) async {
    try {
      final currentUser = _ref.watch(userProvider)!;
      final commentVote = CommentVote(
        uid: currentUser.uid,
        commentId: commentId,
        isUpvoted: isUpvoted,
        createdAt: Timestamp.now(),
      );
      return await _commentRepository.voteComment(commentVote);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<bool?> getCommentVoteStatus(String commentId) {
    final currentUser = _ref.read(userProvider)!;
    return _commentRepository.getCommentVoteStatus(commentId, currentUser.uid);
  }

  Stream<Map<String, int>> getCommentVoteCount(String commentId) {
    return _commentRepository.getCommentVoteCount(commentId);
  }
}
