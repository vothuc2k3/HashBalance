import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/common/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/providers/storage_repository_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/post.dart';

final postRepositoryProvider = Provider((ref) {
  return PostRepository(
      firestore: ref.read(firebaseFirestoreProvider),
      storageRepository: ref.read(storageRepositoryProvider));
});

class PostRepository {
  final FirebaseFirestore _firestore;
  final StorageRepository _storageRepository;

  PostRepository({
    required FirebaseFirestore firestore,
    required StorageRepository storageRepository,
  })  : _firestore = firestore,
        _storageRepository = storageRepository;

  // Stream<Post> getPostsByUserCommunities(List<String> communitiesName) {

  // }

  FutureVoid createPost(
    Post post,
    File? image,
    File? video,
  ) async {
    try {
      final postId = post.uid + Timestamp.now().toString();
      Post updatedPost = post;
      if (image != null) {
        final result = await _storageRepository.storeFile(
          path: 'posts/images',
          id: postId,
          file: image,
        );
        await result.fold(
            (error) => throw FirebaseException(
                  plugin: 'Firebase Exception',
                  message: error.message,
                ), (right) async {
          String imageUrl = await FirebaseStorage.instance
              .ref('posts/images/$postId')
              .getDownloadURL();
          updatedPost = updatedPost.copyWith(image: imageUrl);
        });
      }
      if (video != null) {
        final result = await _storageRepository.storeFile(
          path: 'posts/videos',
          id: postId,
          file: video,
        );
        await result.fold(
            (error) => throw FirebaseException(
                  plugin: 'Firebase Exception',
                  message: error.message,
                ), (right) async {
          String videoUrl = await FirebaseStorage.instance
              .ref('posts/videos/$postId')
              .getDownloadURL();
          updatedPost = updatedPost.copyWith(video: videoUrl);
        });
      }
      right(_posts.doc().set(updatedPost.toMap()));
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //REFERENCE ALL THE POSTS
  CollectionReference get _posts =>
      _firestore.collection(FirebaseConstants.postsCollection);
}
