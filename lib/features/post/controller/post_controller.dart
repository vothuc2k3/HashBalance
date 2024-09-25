import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/storage_repository_providers.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/comment/controller/comment_controller.dart';
import 'package:hash_balance/features/post/repository/post_repository.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';
import 'package:hash_balance/models/poll_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/features/push_notification/controller/push_notification_controller.dart';
import 'package:uuid/uuid.dart';

final getPostCommentCountProvider = FutureProvider.family((ref, String postId) {
  return ref.read(postControllerProvider.notifier).getPostCommentCount(postId);
});

final getPostVoteCountProvider = FutureProvider.family((ref, Post post) {
  return ref
      .watch(postControllerProvider.notifier)
      .getPostVoteCountAndStatus(post);
});

final postControllerProvider = StateNotifierProvider<PostController, bool>(
  (ref) => PostController(
      commentController: ref.watch(commentControllerProvider.notifier),
      postRepository: ref.watch(postRepositoryProvider),
      pushNotificationController:
          ref.watch(pushNotificationControllerProvider.notifier),
      storageRepository: ref.watch(storageRepositoryProvider),
      ref: ref),
);

class PostController extends StateNotifier<bool> {
  final PostRepository _postRepository;
  final StorageRepository _storageRepository;
  final PushNotificationController _pushNotificationController;
  final Ref _ref;
  final CommentController _commentController;
  final Uuid _uuid = const Uuid();

  PostController({
    required PostRepository postRepository,
    required StorageRepository storageRepository,
    required PushNotificationController pushNotificationController,
    required CommentController commentController,
    required Ref ref,
  })  : _postRepository = postRepository,
        _storageRepository = storageRepository,
        _pushNotificationController = pushNotificationController,
        _commentController = commentController,
        _ref = ref,
        super(false);

  //CREATE A NEW POST
  Future<Either<Failures, void>> createPost(
    Community community,
    File? image,
    File? video,
    String content,
  ) async {
    try {
      if (content.isEmpty && image == null && video == null) {
        return left(Failures('Post cannot be empty'));
      }
      final uid = _ref.watch(userProvider)!.uid;
      switch (community.type) {
        case 'Public':
          final post = Post(
            communityId: community.id,
            uid: uid,
            content: content,
            status: 'Approved',
            commentCount: 0,
            shareCount: 0,
            isEdited: false,
            isPinned: false,
            createdAt: Timestamp.now(),
            id: _uuid.v1(),
          );
          final result = await _postRepository.createPost(post, image, video);
          return result;
        default:
          final post = Post(
            communityId: community.id,
            uid: uid,
            content: content,
            status: 'Pending',
            isEdited: false,
            isPinned: false,
            commentCount: 0,
            shareCount: 0,
            createdAt: Timestamp.now(),
            id: _uuid.v1(),
          );
          final result = await _postRepository.createPost(post, image, video);
          return result;
      }
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<Map<String, dynamic>> getPostVoteCountAndStatus(Post post) {
    final currentUser = _ref.watch(userProvider)!;
    return _postRepository.getPostVoteCountAndStatus(post, currentUser.uid);
  }

  Stream<Map<String, dynamic>> getPostVoteCountAndStatusStream(Post post) {
    final currentUser = _ref.watch(userProvider)!;
    return _postRepository.getPostVoteCountAndStatusStream(
        post, currentUser.uid);
  }

  Future<Either<Failures, void>> deletePost(Post post) async {
    state = true;
    try {
      final user = _ref.watch(userProvider)!;
      Either<Failures, void> result;
      if (user.uid == post.uid) {
        result = await _postRepository.deletePost(post, user.uid);
        result.fold((l) => left(l), (r) async {
          if (post.image != '') {
            _storageRepository.deleteFile(
              path: 'posts/images/${post.id}',
            );
          }
          if (post.video != '') {
            _storageRepository.deleteFile(
              path: 'posts/videos/${post.id}',
            );
          }
          await _commentController.clearPostComments(post.id);
        });
      } else {
        return left(Failures('You are not the author of the post'));
      }
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    } finally {
      state = false;
    }
  }

  Future<List<PostDataModel>> getPendingPosts(Community community) {
    return _postRepository.getPendingPosts(community);
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

  Future<Either<Failures, void>> updatePostStatus(
      Post post, String status) async {
    return await _postRepository.updatePostStatus(post, status);
  }

  Future<Either<Failures, void>> createPoll(
    String communityId,
    String question,
    List<String> options,
  ) async {
    List<Map<String, dynamic>> pollOptions = [];
    for (var option in options) {
      if (option.isEmpty) {
        return left(Failures('Option cannot be empty'));
      } else {
        final pollOption = PollOption(
          option: option,
          voteMap: {},
        );
        pollOptions.add(pollOption.toMap());
      }
    }
    final poll = Poll(
      id: _uuid.v1(),
      uid: _ref.read(userProvider)!.uid,
      communityId: communityId,
      question: question,
      options: pollOptions,
      createdAt: Timestamp.now(),
    );
    
    return await _postRepository.createPoll(poll);
  }
}
