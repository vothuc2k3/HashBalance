import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/vote_post/repository/vote_post_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/models/post_vote_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final upvotePostControllerProvider =
    StateNotifierProvider<UpvotePostController, bool>((ref) {
  return UpvotePostController(
      votePostRepository: ref.read(votePostRepositoryProvider), ref: ref);
});
final downvotePostControllerProvider =
    StateNotifierProvider<DownvotePostController, bool>((ref) {
  return DownvotePostController(
      votePostRepository: ref.read(votePostRepositoryProvider), ref: ref);
});

class UpvotePostController extends StateNotifier<bool> {
  final VotePostRepository _votePostRepository;
  final Ref _ref;
  UpvotePostController({
    required VotePostRepository votePostRepository,
    required Ref ref,
  })  : _votePostRepository = votePostRepository,
        _ref = ref,
        super(false);

  FutureVoid votePost(Post post) async {
    try {
      final user = _ref.read(userProvider)!;
      final postVoteModel = PostVote(
        id: await generateRandomId(),
        uid: user.uid,
        postId: post.id,
        isUpvoted: true,
        createdAt: Timestamp.now(),
      );
      await _votePostRepository.votePost(postVoteModel, post);
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    } 
  }
}

class DownvotePostController extends StateNotifier<bool> {
  final VotePostRepository _votePostRepository;
  final Ref _ref;
  DownvotePostController({
    required VotePostRepository votePostRepository,
    required Ref ref,
  })  : _votePostRepository = votePostRepository,
        _ref = ref,
        super(false);

  FutureVoid votePost(Post post) async {
    try {
      final user = _ref.read(userProvider)!;
      final postVoteModel = PostVote(
        id: await generateRandomId(),
        uid: user.uid,
        postId: post.id,
        isUpvoted: false,
        createdAt: Timestamp.now(),
      );
      await _votePostRepository.votePost(postVoteModel, post);
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }
}
