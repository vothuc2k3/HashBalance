import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/storage_repository_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/comment/controller/comment_controller.dart';
import 'package:hash_balance/features/post/repository/post_repository.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/post_vote_model.dart';
import 'package:hash_balance/features/push_notification/controller/push_notification_controller.dart';

final getPostCommentCountProvider = FutureProvider.family((ref, String postId) {
  return ref.read(postControllerProvider.notifier).getPostCommentCount(postId);
});

final getPendingPostsProvider =
    StreamProvider.family.autoDispose((ref, String communityId) {
  return ref
      .watch(postControllerProvider.notifier)
      .getPendingPosts(communityId);
});

final getPostVoteCountProvider = FutureProvider.family((ref, Post post) {
  return ref.watch(postControllerProvider.notifier).getPostVoteCountAndStatus(post);
});

final getPostVoteStatusProvider = StreamProvider.family((ref, Post post) {
  return ref.watch(postControllerProvider.notifier).getPostVoteStatus(post);
});

final fetchCommunityPostsProvider = StreamProvider.family.autoDispose(
    (ref, String communityId) => ref
        .watch(postControllerProvider.notifier)
        .fetchCommunityPosts(communityId));

final getPostByIdProvider =
    StreamProvider.autoDispose.family((ref, String postId) {
  return ref.watch(postControllerProvider.notifier).getPostById(postId);
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
  FutureString createPost(
    Community community,
    File? image,
    File? video,
    String content,
  ) async {
    state = true;
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
            upvoteCount: 0,
            downvoteCount: 0,
            commentCount: 0,
            shareCount: 0,
            isEdited: false,
            createdAt: Timestamp.now(),
            id: await generateRandomId(),
          );
          final result = await _postRepository.createPost(post, image, video);
          return result.fold(
            (l) => left((Failures(l.message))),
            (r) => right('Your Post Was Successfuly Uploaded!'),
          );
        default:
          final post = Post(
            communityId: community.id,
            uid: uid,
            content: content,
            status: 'Pending',
            isEdited: false,
            upvoteCount: 0,
            downvoteCount: 0,
            commentCount: 0,
            shareCount: 0,
            createdAt: Timestamp.now(),
            id: await generateRandomId(),
          );
          final result = await _postRepository.createPost(post, image, video);
          return result.fold(
            (l) => left(
              (Failures(l.message)),
            ),
            (r) => right('Your Post Are Now Pending To Be Approved!'),
          );
      }
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    } finally {
      state = false;
    }
  }

  FutureVoid votePost(Post post, bool userVote) async {
    try {
      final currentUser = _ref.read(userProvider)!;
      final postVoteModel = PostVote(
        id: await generateRandomId(),
        postId: post.id,
        uid: currentUser.uid,
        isUpvoted: userVote,
        createdAt: Timestamp.now(),
      );

      await _postRepository.votePost(postVoteModel, post);
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(
        e.toString(),
      ));
    }
  }

  Stream<bool?> getPostVoteStatus(Post post) {
    try {
      final uid = _ref.watch(userProvider)!.uid;
      return _postRepository.getPostVoteStatus(post, uid);
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  Future<Map<String, dynamic>> getPostVoteCountAndStatus(Post post) async {
    final currentUser = _ref.watch(userProvider)!;
    return await _postRepository.getPostVoteCountAndStatus(post, currentUser.uid);
  }

  FutureVoid deletePost(Post post) async {
    state = true;
    try {
      final user = _ref.watch(userProvider)!;
      Either<Failures, void> result;
      if (user.uid == post.uid) {
        result = await _postRepository.deletePost(post, user.uid);
        result.fold((l) => left(l), (r) async {
          if (post.image != null) {
            _storageRepository.deleteFile(
              path: 'posts/images/${post.id}',
            );
          }
          if (post.video != null) {
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

  Stream<List<Post>?> fetchCommunityPosts(String communityId) {
    return _postRepository.fetchCommunityPosts(communityId);
  }

  Stream<Post> getPostById(String postId) {
    return _postRepository.getPostById(postId);
  }

  Stream<List<Post>?> getPendingPosts(String communityId) {
    return _postRepository.getPendingPosts(communityId);
  }

  Future<Either<Failures, Post?>> fetchPostByPostId(String postId) async {
    try {
      return await _postRepository.fetchPostByPostId(postId);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
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

  FutureVoid updatePostStatus(Post post, String status) async {
    return await _postRepository.updatePostStatus(post, status);
  }
}
