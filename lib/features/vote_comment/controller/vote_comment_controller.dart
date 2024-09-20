import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hash_balance/features/vote_comment/repository/vote_comment_repository.dart';
import 'package:hash_balance/models/comment_vote.dart';

final upvoteCommentControllerProvider =
    StateNotifierProvider<UpvoteCommentController, bool>((ref) {
  return UpvoteCommentController(
      voteCommentRepository: ref.read(voteCommentRepositoryProvider), ref: ref);
});

final downvoteCommentControllerProvider =
    StateNotifierProvider<DownvoteCommentController, bool>((ref) {
  return DownvoteCommentController(
      voteCommentRepository: ref.read(voteCommentRepositoryProvider), ref: ref);
});

class UpvoteCommentController extends StateNotifier<bool> {
  final VoteCommentRepository _voteCommentRepository;
  final Ref _ref;

  UpvoteCommentController({
    required VoteCommentRepository voteCommentRepository,
    required Ref ref,
  })  : _voteCommentRepository = voteCommentRepository,
        _ref = ref,
        super(false);

  Future<Either<Failures, void>> voteComment(String commentId) async {
    try {
      final user = _ref.watch(userProvider)!;
      final commentVoteModel = CommentVote(
        id: getUids(user.uid, commentId),
        commentId: commentId,
        uid: user.uid,
        isUpvoted: true,
        createdAt: Timestamp.now(),
      );
      await _voteCommentRepository.voteComment(commentVoteModel, commentId);
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }
}

class DownvoteCommentController extends StateNotifier<bool> {
  final VoteCommentRepository _voteCommentRepository;
  final Ref _ref;

  DownvoteCommentController({
    required VoteCommentRepository voteCommentRepository,
    required Ref ref,
  })  : _voteCommentRepository = voteCommentRepository,
        _ref = ref,
        super(false);

  Future<Either<Failures, void>> voteComment(String commentId) async {
    try {
      final user = _ref.read(userProvider)!;
      final commentVoteModel = CommentVote(
        id: getUids(user.uid, commentId),
        commentId: commentId,
        uid: user.uid,
        isUpvoted: false,
        createdAt: Timestamp.now(),
      );
      await _voteCommentRepository.voteComment(commentVoteModel, commentId);
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }
}
