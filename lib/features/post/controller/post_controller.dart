import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/post/repository/post_repository.dart';
import 'package:hash_balance/models/comment_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';

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
      final post = Post(
        communityName: communityName,
        uid: uid,
        content: content,
        image: '',
        video: '',
        createdAt: Timestamp.now(),
        upvotes: 0,
        downvotes: 0,
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

  //COMMENT
  FutureString comment(
    UserModel user,
    Post post,
    String? content,
    File? image,
    File? video,
  ) async {
    state = true;
    try {
      final comment = Comment(
        uid: user.uid,
        postId: post.id,
        createdAt: Timestamp.now(),
        content: content,
        image: '',
        video: '',
      );
      final result = await _postRepository.comment(
        user,
        post,
        comment,
        content,
        image,
        video,
      );
      return result.fold(
        (l) => left((Failures(l.message))),
        (r) => right('Comment Was Successfully Done!'),
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
