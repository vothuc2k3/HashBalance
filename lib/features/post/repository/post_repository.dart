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
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/models/post_downvote_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/post_upvote_model.dart';

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
  FutureVoid upvote(PostUpvote postUpvote, String authorUid) async {
    try {
      final postDownvoteId =
          getPostDownvoteId(postUpvote.uid, postUpvote.postId);

      final existingUpvote = await _postUpvotes.doc(postUpvote.id).get();

      final existingDownvote = await _postDownvotes.doc(postDownvoteId).get();

      if (existingUpvote.exists) {
        await _postUpvotes.doc(postUpvote.id).delete();
      } else {
        if (existingDownvote.exists) {
          await _postDownvotes.doc(postDownvoteId).delete();
        }
        await _postUpvotes.doc(postUpvote.id).set(postUpvote.toMap());
      }
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

// DOWNVOTE A POST
  FutureVoid downvote(PostDownvote postDownvote, String authorUid) async {
    try {
      final postUpvoteId =
          getPostUpvoteId(postDownvote.uid, postDownvote.postId);

      final existingDownvote = await _postDownvotes.doc(postDownvote.id).get();

      final existingUpvote = await _postUpvotes.doc(postUpvoteId).get();

      if (existingDownvote.exists) {
        await _postDownvotes.doc(postDownvote.id).delete();
      } else {
        if (existingUpvote.exists) {
          await _postUpvotes.doc(postUpvoteId).delete();
        }
        await _postDownvotes.doc(postDownvote.id).set(postDownvote.toMap());
      }
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //CHECK IF THE USER UPVOTED THE POST
  Stream<bool> checkDidUpvote(String postUpvoteId) {
    return _postUpvotes.doc(postUpvoteId).snapshots().map((event) {
      return event.exists;
    });
  }

  //CHECK IF THE USER DOWNVOTED THE POST
  Stream<bool> checkDidDownvote(String postDownvoteId) {
    return _postDownvotes.doc(postDownvoteId).snapshots().map((event) {
      return event.exists;
    });
  }

  //GET THE UPVOTE COUNTS OF THE POSTS
  Stream<int> getUpvotes(String postId) {
    return _postUpvotes
        .where('postId', isEqualTo: postId)
        .snapshots()
        .map((event) {
      return event.docs.length;
    });
  }

  //GET THE DOWNVOTE COUNTS OF THE POSTS
  Stream<int> getDownvotes(String postId) {
    return _postDownvotes
        .where('postId', isEqualTo: postId)
        .snapshots()
        .map((event) {
      return event.docs.length;
    });
  }

  //DELETE THE POST
  FutureVoid deletePost(Post post, String uid) async {
    final batch = FirebaseFirestore.instance.batch();
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

  //GET POST DATA BY ID
  //TODO: CHECK THIS FUNCTION
  Stream<Post> getPostById(String postId) {
    return _posts.doc(postId).snapshots().map((event) {
      final data = event.data() as Map<String, dynamic>;
      return Post(
        id: postId,
        communityName: data['communityName'] as String,
        uid: data['uid'] as String,
        createdAt: data['createdAt'] as Timestamp,
      );
    });
  }

  //FETCH POSTS BY COMMUNITIES
  Stream<List<Post>?> fetchCommunityPosts(String communityName) {
    return _posts
        .where('communityName', isEqualTo: communityName)
        .snapshots()
        .map((event) {
      if (event.docs.isEmpty) {
        return null;
      }
      var communityPosts = <Post>[];
      for (var doc in event.docs) {
        final postData = doc.data() as Map<String, dynamic>;
        var content = postData['content'] ?? '';
        var image = postData['image'] ?? '';
        var video = postData['video'] ?? '';
        communityPosts.add(
          Post(
            video: video as String,
            image: image as String,
            content: content as String,
            communityName: postData['communityName'] as String,
            uid: postData['uid'] as String,
            createdAt: postData['createdAt'] as Timestamp,
            id: postData['id'] as String,
          ),
        );
      }
      return communityPosts;
    });
  }

  //REFERENCE ALL THE POSTS
  CollectionReference get _posts =>
      _firestore.collection(FirebaseConstants.postsCollection);
  //REFERENCE ALL THE USERS
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);
  //REFERENCE ALL THE POSTS
  CollectionReference get _postUpvotes =>
      _firestore.collection(FirebaseConstants.postUpvoteCollection);
  //REFERENCE ALL THE POSTS
  CollectionReference get _postDownvotes =>
      _firestore.collection(FirebaseConstants.postDownvoteCollection);
}
