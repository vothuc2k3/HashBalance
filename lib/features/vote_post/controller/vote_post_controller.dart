import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/activity_log/controller/activity_log_controller.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/vote_post/repository/vote_post_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/models/post_vote_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final upvotePostControllerProvider =
    StateNotifierProvider<UpvotePostController, bool>((ref) {
  return UpvotePostController(
    votePostRepository: ref.read(votePostRepositoryProvider),
    activityLogController: ref.read(activityLogControllerProvider.notifier),
    ref: ref,
  );
});
final downvotePostControllerProvider =
    StateNotifierProvider<DownvotePostController, bool>((ref) {
  return DownvotePostController(
    votePostRepository: ref.read(votePostRepositoryProvider),
    activityLogController: ref.read(activityLogControllerProvider.notifier),
    ref: ref,
  );
});

class UpvotePostController extends StateNotifier<bool> {
  final VotePostRepository _votePostRepository;
  final ActivityLogController _activityLogController;
  final Ref _ref;
  UpvotePostController({
    required VotePostRepository votePostRepository,
    required ActivityLogController activityLogController,
    required Ref ref,
  })  : _votePostRepository = votePostRepository,
        _activityLogController = activityLogController,
        _ref = ref,
        super(false);

  Future<Either<Failures, void>> votePost({
    required Post post,
    required String postAuthorName,
    required String communityName,
  }) async {
    try {
      final user = _ref.watch(userProvider)!;
      final postVoteModel = PostVote(
        id: getUids(post.id, user.uid),
        uid: user.uid,
        postId: post.id,
        isUpvoted: true,
        createdAt: Timestamp.now(),
      );
      final result = await _votePostRepository.votePost(postVoteModel, post);
      return result.fold(
        (l) => left(l),
        (r) {
          _activityLogController.addUpvoteActivityLog(
            postAuthorName: postAuthorName,
            communityName: communityName,
          );
          return right(null);
        },
      );
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }
}

class DownvotePostController extends StateNotifier<bool> {
  final VotePostRepository _votePostRepository;
  final ActivityLogController _activityLogController;
  final Ref _ref;
  DownvotePostController({
    required VotePostRepository votePostRepository,
    required ActivityLogController activityLogController,
    required Ref ref,
  })  : _votePostRepository = votePostRepository,
        _activityLogController = activityLogController,
        _ref = ref,
        super(false);

  Future<Either<Failures, void>> votePost({
    required Post post,
    required String postAuthorName,
    required String communityName,
  }) async {
    try {
      final user = _ref.read(userProvider)!;
      final postVoteModel = PostVote(
        id: getUids(post.id, user.uid),
        uid: user.uid,
        postId: post.id,
        isUpvoted: false,
        createdAt: Timestamp.now(),
      );
      final result = await _votePostRepository.votePost(postVoteModel, post);
      return result.fold(
        (l) => left(l),
        (r) {
          _activityLogController.addDownvoteActivityLog(
            postAuthorName: postAuthorName,
            communityName: communityName,
          );
          return right(null);
        },
      );
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }
}
