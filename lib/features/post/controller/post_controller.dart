import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/features/post/repository/post_repository.dart';
import 'package:hash_balance/models/post_model.dart';

// final postsProvider = StreamProvider.family((ref, List<String> communityName) {
//   return ref
//       .watch(postControllerProvider.notifier)
//       .getPostsByUserCommunities(communityName);
// });

final postControllerProvider = StateNotifierProvider<PostController, bool>(
    (ref) => PostController(
        postRepository: ref.read(postRepositoryProvider), ref: ref));

class PostController extends StateNotifier<bool> {
  final PostRepository _postRepository;

  PostController({
    required PostRepository postRepository,
    required Ref ref,
  })  : _postRepository = postRepository,
        super(false);

  //GET THE POSTS BY USER COMMUNITIES
  // Stream<List<Post>> getPostsByUserCommunities(String uid) {
  //   return _postRepository.getPostsByUserCommunities(uid);
  // }

  FutureString createPost(
    String uid,
    String communityName,
    File? image,
    File? video,
    String? content,
  ) async {
    state = true;
    try {
      final post = Post(
        communityName: communityName,
        uid: uid,
        content: content,
        image: '',
        video: '',
        createdAt: Timestamp.now(),
        upvotes: 0,
        downvotes: 0,
        comments: [],
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
}