import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/post/repository/post_repository.dart';
import 'package:hash_balance/models/post_downvote_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/post_upvote_model.dart';

final fetchCommunityPostsProvider = StreamProvider.family(
    (ref, String communityName) => ref
        .watch(postControllerProvider.notifier)
        .fetchCommunityPosts(communityName));

final postControllerProvider = StateNotifierProvider<PostController, bool>(
  (ref) => PostController(
      postRepository: ref.read(postRepositoryProvider), ref: ref),
);

final getPostByIdProvider = StreamProvider.family((ref, String postId) {
  return ref.watch(postControllerProvider.notifier).getPostById(postId);
});

final getPostUpvoteStatusProvider = StreamProvider.family((ref, String postId) {
  return ref.watch(postControllerProvider.notifier).checkDidUpvote(postId);
});

final getPostDownvoteStatusProvider =
    StreamProvider.family((ref, String postId) {
  return ref.watch(postControllerProvider.notifier).checkDidDownvote(postId);
});

final getPostUpvoteCountProvider = StreamProvider.family((ref, String postId) {
  return ref.watch(postControllerProvider.notifier).getUpvotes(postId);
});

final getPostDownvoteCountProvider =
    StreamProvider.family((ref, String postId) {
  return ref.watch(postControllerProvider.notifier).getDownvotes(postId);
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
    String communityName,
    File? image,
    File? video,
    String? content,
  ) async {
    try {
      final post = Post(
        communityName: communityName,
        uid: uid,
        content: content,
        createdAt: Timestamp.now(),
        id: await generateRandomId(),
      );
      final result = await _postRepository.createPost(post, image, video);
      return result.fold(
        (l) => left((Failures(l.message))),
        (r) => right('Your Post Was Successfuly Uploaded!'),
      );
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  FutureVoid upvote(String postId, String authorUid) async {
    try {
      final user = _ref.watch(userProvider);

      final postUpvote = PostUpvote(
        id: getPostUpvoteId(user!.uid, postId),
        postId: postId,
        uid: user.uid,
        createdAt: Timestamp.now(),
      );
      final result = await _postRepository.upvote(postUpvote, authorUid);
      return result.fold(
        (l) {
          return left(Failures(l.message));
        },
        (r) {
          return right(null);
        },
      );
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  FutureVoid downvote(String postId, String authorUid) async {
    try {
      final user = _ref.read(userProvider);

      final postDownvote = PostDownvote(
        id: getPostDownvoteId(user!.uid, postId),
        postId: postId,
        uid: user.uid,
        createdAt: Timestamp.now(),
      );
      final result = await _postRepository.downvote(postDownvote, authorUid);
      return result.fold(
        (l) {
          return left(Failures(l.message));
        },
        (r) {
          return right(null);
        },
      );
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<bool> checkDidUpvote(String postId) {
    final user = _ref.read(userProvider);
    return _postRepository.checkDidUpvote(getPostUpvoteId(user!.uid, postId));
  }

  Stream<int> getUpvotes(String postId) {
    return _postRepository.getUpvotes(postId);
  }

  Stream<bool> checkDidDownvote(String postId) {
    final user = _ref.read(userProvider);
    return _postRepository
        .checkDidDownvote(getPostDownvoteId(user!.uid, postId));
  }

  Stream<int> getDownvotes(String postId) {
    return _postRepository.getDownvotes(postId);
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

  Stream<List<Post>?> fetchCommunityPosts(String communityName) {
    return _postRepository.fetchCommunityPosts(communityName);
  }

  Stream<Post> getPostById(String postId) {
    return _postRepository.getPostById(postId);
  }
}
