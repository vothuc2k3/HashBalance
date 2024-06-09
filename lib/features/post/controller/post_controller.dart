import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/post/repository/post_repository.dart';
import 'package:hash_balance/models/post_model.dart';

final postControllerProvider = StateNotifierProvider<PostController, bool>(
  (ref) => PostController(
      postRepository: ref.read(postRepositoryProvider), ref: ref),
);

final getUpvoteStatusProvider = StreamProvider.family((ref, String postId) {
  return ref.watch(postControllerProvider.notifier).checkDidUpvote(postId);
});

final getDownvoteStatusProvider = StreamProvider.family((ref, String postId) {
  return ref.watch(postControllerProvider.notifier).checkDidDownvote(postId);
});

final getUpvoteCountProvider = StreamProvider.family((ref, String postId) {
  return ref.watch(postControllerProvider.notifier).getUpvotes(postId);
});

final getDownvoteCountProvider = StreamProvider.family((ref, String postId) {
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
    state = true;
    try {
      List<String> upvotes = ['empty'];
      List<String> downvotes = ['empty'];
      upvotes.clear();
      downvotes.clear();
      final post = Post(
        communityName: communityName,
        uid: uid,
        content: content,
        createdAt: Timestamp.now(),
        upvotes: upvotes,
        downvotes: downvotes,
        id: generateRandomPostId(),
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
    } finally {
      state = false;
    }
  }



  FutureVoid upvote(String postId) async {
    state = true;
    try {
      final user = _ref.read(userProvider);
      await _postRepository.upvote(postId, user!.uid);
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    } finally {
      state = false;
    }
  }

  FutureVoid downvote(String postId) async {
    state = true;
    try {
      final user = _ref.read(userProvider);
      await _postRepository.downvote(postId, user!.uid);
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    } finally {
      state = false;
    }
  }

  Stream<bool> checkDidUpvote(String postId) {
    final user = _ref.read(userProvider);
    return _postRepository.checkDidUpvote(postId, user!.uid);
  }

  Stream<int> getUpvotes(String postId) {
    return _postRepository.getUpvotes(postId);
  }

  Stream<bool> checkDidDownvote(String postId) {
    final user = _ref.read(userProvider);
    return _postRepository.checkDidDownvote(postId, user!.uid);
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
}
