import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/storage_repository.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/comment/controller/comment_controller.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/post/repository/post_repository.dart';
import 'package:hash_balance/features/post_share/controller/post_share_controller.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';
import 'package:hash_balance/models/poll_option_vote_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/features/push_notification/controller/push_notification_controller.dart';
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
      pushNotificationController:
          ref.read(pushNotificationControllerProvider.notifier),
      moderationController: ref.read(moderationControllerProvider.notifier),
      storageRepository: ref.read(storageRepositoryProvider),
      ref: ref),
);

class PostController extends StateNotifier<bool> {
  final PostRepository _postRepository;
  final StorageRepository _storageRepository;
  final PushNotificationController _pushNotificationController;
  final ModerationController _moderationController;
  final PostShareController _postShareController;
  final Ref _ref;
  final CommentController _commentController;
  final Uuid _uuid = const Uuid();

  PostController({
    required PostRepository postRepository,
    required StorageRepository storageRepository,
    required PushNotificationController pushNotificationController,
    required ModerationController moderationController,
    required PostShareController postShareController,
    required CommentController commentController,
    required Ref ref,
  })  : _postRepository = postRepository,
        _storageRepository = storageRepository,
        _pushNotificationController = pushNotificationController,
        _moderationController = moderationController,
        _postShareController = postShareController,
        _commentController = commentController,
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
      }
      final uid = _ref.read(userProvider)!.uid;
      final role = await _moderationController.getMemberRole(uid, community.id);
      if (role == 'suspended') {
        return left(Failures('You are suspended from this community'));
      }

      switch (community.type) {
        case 'Public':
          postStatus = 'Approved';
          final post = Post(
            communityId: community.id,
            uid: uid,
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
        default:
          role == 'moderator'
              ? postStatus = 'Approved'
              : postStatus = 'Pending';
          final post = Post(
            communityId: community.id,
            uid: uid,
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
      final user = _ref.watch(userProvider)!;
      Either<Failures, void> result;
      if (user.uid == post.uid) {
        result = await _postRepository.deletePost(post, user.uid);
        result.fold((l) => left(l), (r) async {
          if (post.images != null || post.images!.isNotEmpty) {
            for (var image in post.images!) {
              await _storageRepository.deleteFile(
                path: 'posts/images/${post.id}/$image',
              );
            }
          }
          if (post.video != '' || post.video != null) {
            await _storageRepository.deleteFile(
              path: 'posts/videos/${post.id}',
            );
          }
          await _commentController.clearPostComments(post.id);
          await _postShareController.deletePostShareByPostId(post.id);
        });
      } else {
        return left(Failures('You are not the author of the post'));
      }
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
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
    return await _postRepository.updatePoll(poll, pollOptions);
  }

  Future<Either<Failures, void>> updatePost(
      Post post, List<File>? images, File? video) async {
    return await _postRepository.updatePost(
      post,
      images,
      video,
    );
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
