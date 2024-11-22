import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/constants.dart';

import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/storage_repository.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/cloud_vision/controller/cloud_vision_controller.dart';
import 'package:hash_balance/features/comment/controller/comment_controller.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/features/friend/controller/friend_controller.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/perspective_api/controller/perspective_api_controller.dart';
import 'package:hash_balance/features/post/repository/post_repository.dart';
import 'package:hash_balance/features/post_share/controller/post_share_controller.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';
import 'package:hash_balance/models/poll_option_vote_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';
import 'package:hash_balance/models/poll_option_model.dart';

final hashtagPostsProvider = StreamProvider.family((ref, String hashtag) {
  return ref
      .watch(postControllerProvider.notifier)
      .getHashtagPosts(hashtag: hashtag);
});

final getPostVoteCountAndStatusProvider =
    StreamProvider.family((ref, Post post) {
  return ref
      .watch(postControllerProvider.notifier)
      .getPostVoteCountAndStatus(post);
});

final getPostVoteCountsProvider =
    StreamProvider.family<Map<String, int>, Post>((ref, Post post) {
  return ref
      .watch(postControllerProvider.notifier)
      .getPostVoteCountsStream(post);
});

final getUserVoteStatusProvider =
    StreamProvider.family<Map<String, String?>, Post>(
  (ref, Post post) {
    return ref
        .watch(postControllerProvider.notifier)
        .getUserVoteStatusStream(post);
  },
);

final getPollOptionsProvider = StreamProvider.family((ref, String pollId) {
  return ref
      .watch(postControllerProvider.notifier)
      .getPollOptions(pollId: pollId);
});

final getPendingPostsProvider =
    StreamProvider.family((ref, String communityId) {
  return ref
      .watch(postControllerProvider.notifier)
      .getPendingPosts(communityId);
});

final getPollOptionVotesCountAndUserVoteStatusProvider =
    StreamProvider.family((ref, Tuple2<String, String> data) {
  return ref
      .watch(postControllerProvider.notifier)
      .getPollOptionVotesCountAndUserVoteStatus(
          pollId: data.item1, optionId: data.item2);
});

final getUserPollOptionVoteProvider =
    StreamProvider.family((ref, String pollId) {
  return ref
      .watch(postControllerProvider.notifier)
      .getUserPollOptionVote(pollId: pollId);
});

final getPostCommentCountProvider = FutureProvider.family((ref, String postId) {
  return ref.read(postControllerProvider.notifier).getPostCommentCount(postId);
});

final postControllerProvider = StateNotifierProvider<PostController, bool>(
  (ref) => PostController(
      commentController: ref.read(commentControllerProvider.notifier),
      postRepository: ref.read(postRepositoryProvider),
      postShareController: ref.read(postShareControllerProvider.notifier),
      friendController: ref.read(friendControllerProvider.notifier),
      moderationController: ref.read(moderationControllerProvider.notifier),
      communityController: ref.read(communityControllerProvider.notifier),
      storageRepository: ref.read(storageRepositoryProvider),
      cloudVisionController: ref.read(cloudVisionControllerProvider),
      perspectiveApiController: ref.read(perspectiveApiControllerProvider),
      ref: ref),
);

class PostController extends StateNotifier<bool> {
  final PostRepository _postRepository;
  final StorageRepository _storageRepository;
  final ModerationController _moderationController;
  final CommunityController _communityController;
  final FriendController _friendController;
  final PostShareController _postShareController;
  final CloudVisionController _cloudVisionController;
  final Ref _ref;
  final CommentController _commentController;
  final PerspectiveApiController _perspectiveApiController;
  final Uuid _uuid = const Uuid();

  PostController({
    required PostRepository postRepository,
    required StorageRepository storageRepository,
    required ModerationController moderationController,
    required CommunityController communityController,
    required FriendController friendController,
    required PostShareController postShareController,
    required CommentController commentController,
    required CloudVisionController cloudVisionController,
    required PerspectiveApiController perspectiveApiController,
    required Ref ref,
  })  : _postRepository = postRepository,
        _storageRepository = storageRepository,
        _moderationController = moderationController,
        _communityController = communityController,
        _friendController = friendController,
        _postShareController = postShareController,
        _commentController = commentController,
        _cloudVisionController = cloudVisionController,
        _perspectiveApiController = perspectiveApiController,
        _ref = ref,
        super(false);

  //CREATE A NEW POST
  Future<Either<Failures, void>> createPost({
    required Community community,
    List<File>? images,
    File? video,
    required String content,
  }) async {
    state = true;
    try {
      late String postStatus;
      if (content.isEmpty && images == null && video == null) {
        return left(Failures('Post cannot be empty'));
      } else {
        final errorMessage =
            await _perspectiveApiController.isCommentSafe(content);
        if (errorMessage.isLeft()) {
          return errorMessage as Either<Failures, void>;
        }

        if (errorMessage.isRight() &&
            errorMessage.getOrElse((_) => null) != null) {
          return left(Failures(errorMessage.getOrElse((_) => '')!));
        }
      }

      if (images != null && images.isNotEmpty) {
        final result = await _cloudVisionController.areImagesSafe(images);

        final isSafe = result.fold(
          (failure) => left(failure),
          (isSafe) => right(isSafe),
        );

        if (isSafe.isLeft()) return isSafe as Either<Failures, void>;
        if (isSafe.isRight() && !isSafe.getOrElse((_) => false)) {
          return left(
              Failures('Your images contains inappropriate content...'));
        }
      }

      final user = _ref.read(userProvider)!;
      final role = await _moderationController
          .getMemberRole(
              getMembershipId(uid: user.uid, communityId: community.id))
          .first;
      if (role == 'suspended') {
        return left(Failures('You are suspended from this community'));
      }

      switch (community.type) {
        case 'Public':
          postStatus = 'Approved';
          final post = Post(
            communityId: community.id,
            uid: user.uid,
            content: content,
            status: postStatus,
            isEdited: false,
            isPinned: false,
            isPoll: false,
            createdAt: Timestamp.now(),
            id: _uuid.v1(),
          );
          final result = await _postRepository.createPost(post, images, video);
          result.fold(
            (l) => left(l),
            (r) async {
              await _friendController.notifyFollowers(
                uid: user.uid,
                message:
                    '$user.username has posted a new post in ${community.name}',
                title: 'New Post',
                type: Constants.newPostType,
              );
            },
          );
          return result;
        default:
          role == 'moderator'
              ? postStatus = 'Approved'
              : postStatus = 'Pending';
          final post = Post(
            communityId: community.id,
            uid: user.uid,
            content: content,
            status: postStatus,
            isEdited: false,
            isPinned: false,
            isPoll: false,
            createdAt: Timestamp.now(),
            id: _uuid.v1(),
          );
          final result = await _postRepository.createPost(post, images, video);
          return result;
      }
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    } finally {
      state = false;
    }
  }

  Stream<Map<String, int>> getPostVoteCountsStream(Post post) {
    return _postRepository.getPostVoteCountsStream(post);
  }

  Stream<Map<String, String?>> getUserVoteStatusStream(Post post) {
    final String uid = _ref.read(userProvider)!.uid;
    return _postRepository.getUserVoteStatusStream(post, uid);
  }

  Future<Either<Failures, void>> deletePost(Post post) async {
    try {
      final user = _ref.read(userProvider)!;

      if (user.uid == post.uid ||
          await _isUserModerator(user.uid, post.communityId)) {
        final result = await _postRepository.deletePost(post, user.uid);

        return await result.fold(
          (l) => left(l),
          (r) async {
            final deleteResult = await _storageRepository
                .deletePostImagesAndVideo(postId: post.id);
            deleteResult.fold(
              (failure) => left(failure),
              (_) async {
                await _commentController.clearPostComments(post.id);
                await _postShareController.deletePostShareByPostId(post.id);
              },
            );

            return right(null);
          },
        );
      } else {
        return left(Failures('You are not authorized to delete this post'));
      }
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<bool> _isUserModerator(String userId, String communityId) async {
    final userRole =
        await _communityController.getMemberRole(userId, communityId);
    return userRole == 'moderator';
  }

  Stream<List<PostDataModel>> getPendingPosts(String communityId) {
    return _postRepository.getPendingPosts(communityId: communityId);
  }

  //GET POST COMMENT COUNT
  Future<int> getPostCommentCount(String postId) {
    try {
      return _postRepository.getPostCommentCount(postId);
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  //FETCH PIN POST
  Future<PostDataModel?> getCommunityPinnedPost(Community community) async {
    return await _postRepository.getCommunityPinnedPost(community);
  }

  //GET POST SHARE COUNT
  Future<int> getPostShareCount(String postId) {
    try {
      return _postRepository.getPostShareCount(postId);
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  //UPDATE POST STATUS
  Future<Either<Failures, void>> updatePostStatus(
      Post post, String status) async {
    return await _postRepository.updatePostStatus(post, status);
  }

  //CREATE POLL
  Future<Either<Failures, void>> createPoll({
    required String communityId,
    required String question,
    required List<String> options,
  }) async {
    List<PollOption> pollOptions = [];

    if (question.isEmpty) {
      return left(Failures('Question cannot be empty'));
    } else {
      final errorMessage =
          await _perspectiveApiController.isCommentSafe(question);
      if (errorMessage.isLeft()) {
        return errorMessage as Either<Failures, void>;
      }

      if (errorMessage.isRight() &&
          errorMessage.getOrElse((_) => null) != null) {
        return left(Failures(errorMessage.getOrElse((_) => '')!));
      }
    }
    final poll = Post(
      id: _uuid.v1(),
      uid: _ref.read(userProvider)!.uid,
      communityId: communityId,
      content: question,
      createdAt: Timestamp.now(),
      isPoll: true,
      status: 'Approved',
      isPinned: false,
      isEdited: false,
    );
    for (var option in options) {
      final pollOption = PollOption(
        id: _uuid.v1(),
        pollId: poll.id,
        option: option,
      );
      pollOptions.add(pollOption);
    }
    return await _postRepository.createPoll(
      poll: poll,
      pollOptions: pollOptions,
    );
  }

  //VOTE OPTION
  Future<void> voteOption({
    required String pollId,
    required String optionId,
  }) async {
    final pollOptionVote = PollOptionVote(
      id: getUids(_ref.read(userProvider)!.uid, pollId),
      pollId: pollId,
      pollOptionId: optionId,
      uid: _ref.read(userProvider)!.uid,
    );
    return await _postRepository.voteOption(
      pollOptionVote: pollOptionVote,
    );
  }

  Future<void> deletePoll({required String pollId}) async {
    return await _postRepository.deletePoll(pollId: pollId);
  }

  Stream<String?> getUserPollOptionVote({
    required String pollId,
  }) {
    final currentUser = _ref.read(userProvider)!;
    return _postRepository.getUserPollOptionVote(
        pollId: pollId, uid: currentUser.uid);
  }

  Stream<Tuple2<String?, int>> getPollOptionVotesCountAndUserVoteStatus({
    required String pollId,
    required String optionId,
  }) {
    final currentUser = _ref.read(userProvider)!;
    return _postRepository.getPollOptionVotesCountAndUserVoteStatus(
        pollId: pollId, uid: currentUser.uid, optionId: optionId);
  }

  Stream<List<PollOption>> getPollOptions({required String pollId}) {
    return _postRepository.getPollOptions(pollId: pollId);
  }

  Future<Either<Failures, void>> updatePoll(
    Post poll,
    List<PollOption> pollOptions,
  ) async {
    if (poll.content.isEmpty) {
      return left(Failures('Question cannot be empty'));
    } else {
      final errorMessage =
          await _perspectiveApiController.isCommentSafe(poll.content);
      if (errorMessage.isLeft()) {
        return errorMessage as Either<Failures, void>;
      }

      if (errorMessage.isRight() &&
          errorMessage.getOrElse((_) => null) != null) {
        return left(Failures(errorMessage.getOrElse((_) => '')!));
      }
    }
    return await _postRepository.updatePoll(poll, pollOptions);
  }

  Future<Either<Failures, void>> updatePost(
      Post post, List<File>? images, File? video) async {
    if (post.content.isEmpty) {
      return left(Failures('Post cannot be empty'));
    } else {
      final errorMessage =
          await _perspectiveApiController.isCommentSafe(post.content);
      if (errorMessage.isLeft()) {
        return errorMessage as Either<Failures, void>;
      }

      if (errorMessage.isRight() &&
          errorMessage.getOrElse((_) => null) != null) {
        return left(Failures(errorMessage.getOrElse((_) => '')!));
      }
    }
    return await _postRepository.updatePost(post, images, video);
  }

  Stream<Map<String, dynamic>> getPostVoteCountAndStatus(Post post) {
    final currentUser = _ref.read(userProvider)!;
    return _postRepository.getPostVoteCountAndStatus(post, currentUser.uid);
  }

  Future<Either<Failures, PostDataModel?>> getPostDataByPostId({
    required String postId,
  }) async {
    try {
      return right(await _postRepository.getPostDataByPostId(postId: postId));
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<List<PostDataModel>> getHashtagPosts({required String hashtag}) {
    return _postRepository.getHashtagPosts(hashtag: hashtag);
  }
}
