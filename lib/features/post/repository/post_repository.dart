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
import 'package:hash_balance/models/post_model.dart';

final postRepositoryProvider = Provider((ref) {
  return PostRepository(
      firestore: ref.read(firebaseFirestoreProvider),
      storageRepository: ref.read(storageRepositoryProvider));
});

class PostRepository {
  final FirebaseFirestore _firestore;
  final StorageRepository _storageRepository;
  final batch = FirebaseFirestore.instance.batch();

  PostRepository({
    required FirebaseFirestore firestore,
    required StorageRepository storageRepository,
  })  : _firestore = firestore,
        _storageRepository = storageRepository;

  //CREATE A NEW POST
  FutureVoid createPost(
    Post post,
    File? image,
    File? video,
  ) async {
    try {
      Post updatedPost = post;
      if (image != null) {
        final result = await _storageRepository.storeFile(
          path: 'posts/images',
          id: post.id,
          file: image,
        );
        await result.fold(
            (error) => throw FirebaseException(
                  plugin: 'Firebase Exception',
                  message: error.message,
                ), (right) async {
          String imageUrl = await FirebaseStorage.instance
              .ref('posts/images/${post.id}')
              .getDownloadURL();
          updatedPost = updatedPost.copyWith(image: imageUrl);
        });
      }
      if (video != null) {
        final result = await _storageRepository.storeFile(
          path: 'posts/videos',
          id: post.id,
          file: video,
        );
        await result.fold(
            (error) => throw FirebaseException(
                  plugin: 'Firebase Exception',
                  message: error.message,
                ), (right) async {
          String videoUrl = await FirebaseStorage.instance
              .ref('posts/videos/${post.id}')
              .getDownloadURL();
          updatedPost = updatedPost.copyWith(video: videoUrl);
        });
      }
      await _posts.doc(post.id).set(updatedPost.toMap());
      await _users.doc(post.uid).update({
        'activityPoint': FieldValue.increment(1),
      });
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //UPVOTE A POST
  FutureVoid upvote(String postId, String uid) async {
    try {
      final postDoc = await _posts.doc(postId).get();
      if (postDoc.exists) {
        final data = postDoc.data();
        final postData = data as Map<String, dynamic>;
        var upvotes = List<String>.from(postData['upvotes'] ?? <String>[]);
        var downvotes = List<String>.from(postData['downvotes'] ?? <String>[]);
        var upvoteCount = postData['upvoteCount'] as int;

        final batch = FirebaseFirestore.instance.batch();

        if (downvotes.contains(uid)) {
          downvotes.remove(uid);
          batch.update(_posts.doc(postId), {
            'downvotes': downvotes,
          });
        }

        if (upvotes.contains(uid)) {
          upvotes.remove(uid);
          upvoteCount -= 1;
          batch.update(_posts.doc(postId), {
            'upvotes': upvotes,
            'upvoteCount': upvoteCount,
          });
          batch.update(_users.doc(uid), {
            'activityPoint': FieldValue.increment(-1),
          });
        } else {
          upvotes.add(uid);
          upvoteCount += 1;
          batch.update(_posts.doc(postId), {
            'upvotes': upvotes,
            'upvoteCount': upvoteCount,
          });
          batch.update(_users.doc(uid), {
            'activityPoint': FieldValue.increment(1),
          });
        }
        await batch.commit();
        return right(null);
      } else {
        return left(Failures('Post not found'));
      }
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

// DOWNVOTE A POST
  FutureVoid downvote(String postId, String uid) async {
    try {
      final postDoc = await _posts.doc(postId).get();
      if (postDoc.exists) {
        final data = postDoc.data();
        final postData = data as Map<String, dynamic>;
        var downvotes = List<String>.from(postData['downvotes'] ?? <String>[]);
        var upvotes = List<String>.from(postData['upvotes'] ?? <String>[]);
        var upvoteCount = postData['upvoteCount'] as int;

        final batch = FirebaseFirestore.instance.batch();
        if (upvotes.contains(uid)) {
          upvotes.remove(uid);
          upvoteCount -= 1;
          batch.update(_posts.doc(postId), {
            'upvotes': upvotes,
            'upvoteCount': upvoteCount,
          });
          batch.update(_users.doc(uid), {
            'activityPoint': FieldValue.increment(-1),
          });
        }
        if (downvotes.contains(uid)) {
          downvotes.remove(uid);
          batch.update(_posts.doc(postId), {
            'downvotes': downvotes,
          });
        } else {
          downvotes.add(uid);
          batch.update(_posts.doc(postId), {
            'downvotes': downvotes,
          });
        }
        await batch.commit();
        return right(null);
      } else {
        return left(Failures('Post not found'));
      }
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //CHECK IF THE USER UPVOTED THE POST
  Stream<bool> checkDidUpvote(String postId, String uid) {
    return _posts.doc(postId).snapshots().map((event) {
      final data = event.data() as Map<String, dynamic>;
      final upvotes = List<String>.from(data['upvotes']);
      if (upvotes.contains(uid)) {
        return true;
      } else {
        return false;
      }
    });
  }

  //CHECK IF THE USER DOWNVOTED THE POST
  Stream<bool> checkDidDownvote(String postId, String uid) {
    return _posts.doc(postId).snapshots().map((event) {
      final data = event.data() as Map<String, dynamic>;
      final downvotes = List<String>.from(data['downvotes']);
      if (downvotes.contains(uid)) {
        return true;
      } else {
        return false;
      }
    });
  }

  //GET THE UPVOTE COUNTS OF THE POSTS
  Stream<int> getUpvotes(String postId) {
    return _posts.doc(postId).snapshots().map((event) {
      final data = event.data() as Map<String, dynamic>;
      return List<String>.from(data['upvotes']).length - 1;
    });
  }

  //GET THE DOWNVOTE COUNTS OF THE POSTS
  Stream<int> getDownvotes(String postId) {
    return _posts.doc(postId).snapshots().map((event) {
      final data = event.data() as Map<String, dynamic>;
      if (List<String>.from(data['downvotes']).isEmpty) {
        return 0;
      } else {
        return List<String>.from(data['downvotes']).length - 1;
      }
    });
  }

  //DELETE THE POST
  FutureVoid deletePost(Post post, String uid) async {
    try {
      if (post.uid == uid) {
        batch.delete(_posts.doc(post.id));
        await batch.commit();
        return right(null);
      } else {
        return left(Failures('You are not the owner of the post'));
      }
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //REFERENCE ALL THE POSTS
  CollectionReference get _posts =>
      _firestore.collection(FirebaseConstants.postsCollection);
  //REFERENCE ALL THE USERS
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);
}
