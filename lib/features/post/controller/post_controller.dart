import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/post/repository/post_repository.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/post_vote_model.dart';

final getPendingPostsProvider =
    StreamProvider.family.autoDispose((ref, String communityId) {
  return ref
      .watch(postControllerProvider.notifier)
      .getPendingPosts(communityId);
});

final getPostVoteCountProvider = StreamProvider.family((ref, Post post) {
  return ref.watch(postControllerProvider.notifier).getPostVoteCount(post);
});

final getPostVoteStatusProvider = StreamProvider.family((ref, Post post) {
  return ref.watch(postControllerProvider.notifier).getPostVoteStatus(post);
});

final fetchCommunityPostsProvider = StreamProvider.family(
    (ref, String communityId) => ref
        .watch(postControllerProvider.notifier)
        .fetchCommunityPosts(communityId));

final postControllerProvider = StateNotifierProvider<PostController, bool>(
  (ref) => PostController(
      postRepository: ref.read(postRepositoryProvider), ref: ref),
);

final getPostByIdProvider = StreamProvider.family((ref, String postId) {
  return ref.watch(postControllerProvider.notifier).getPostById(postId);
});

class PostController extends StateNotifier<bool> {
  final PostRepository _postRepository;
  final Ref _ref;

  PostController({
    required PostRepository postRepository,
    required Ref ref,
  })  : _postRepository = postRepository,
        _ref = ref,
        super(false);

  //CREATE A NEW POST
  FutureString createPost(
    String uid,
    Community community,
    File? image,
    File? video,
    String? content,
  ) async {
    try {
      switch (community.type) {
        case 'Public':
          final post = Post(
            communityId: community.id,
            uid: uid,
            content: content,
            status: 'Approved',
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
            createdAt: Timestamp.now(),
            id: await generateRandomId(),
          );
          final result = await _postRepository.createPost(post, image, video);
          return result.fold(
            (l) => left((Failures(l.message))),
            (r) => right('Your Post Are Now Pending To Be Approved!'),
          );
      }
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
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

      await _postRepository.votePost(postVoteModel);
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<bool?> getPostVoteStatus(Post post) {
    try {
      final uid = _ref.read(userProvider)!.uid;
      return _postRepository.getPostVoteStatus(post, uid);
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  Stream<Map<String, int>> getPostVoteCount(Post post) {
    final uid = _ref.read(userProvider)!.uid;
    return _postRepository.getPostVoteCount(post, uid);
  }

  FutureString deletePost(Post post) async {
    state = true;
    try {
      final user = _ref.read(userProvider);
      final result = await _postRepository.deletePost(post, user!.uid);
      return result.fold((l) {
        return left(Failures(l.message));
      }, (r) {
        return right('Successfully Deleted Post');
      });
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
}
