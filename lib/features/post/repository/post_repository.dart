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
import 'package:hash_balance/models/post_vote_model.dart';

final postRepositoryProvider = Provider((ref) {
  return PostRepository(
    firestore: ref.read(firebaseFirestoreProvider),
    storageRepository: ref.read(storageRepositoryProvider),
  );
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

  //VOTE THE POST
  Future<void> votePost(PostVote postVoteModel) async {
    try {
      final querySnapshot = await _postVotes
          .where('postId', isEqualTo: postVoteModel.postId)
          .where('uid', isEqualTo: postVoteModel.uid)
          .get();
      if (querySnapshot.docs.isEmpty) {
        await _postVotes.doc(postVoteModel.id).set(postVoteModel.toMap());
      } else {
        final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
        final postVoteModelId = data['id'] as String;
        final postVoteModelCopy = postVoteModel.copyWith(id: postVoteModelId);
        final isAlreadyUpvoted = data['isUpvoted'] as bool;
        final doWantToUpvote = postVoteModel.isUpvoted;
        if (doWantToUpvote == isAlreadyUpvoted) {
          await _postVotes.doc(postVoteModelId).delete();
        } else {
          await _postVotes
              .doc(postVoteModelId)
              .update(postVoteModelCopy.toMap());
        }
      }
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  //CHECK VOTE STATUS OF A USER TOWARDS A POST
  Future<bool?> getVoteStatus(String currentUid, String postId) async {
    try {
      final querySnapshot = await _postVotes
          .where('postId', isEqualTo: postId)
          .where('uid', isEqualTo: currentUid)
          .get();
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
      return data['isUpvoted'];
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  //GET VOTE COUNT OF A POST
  Stream<Map<String, int>> getPostVoteCount(Post post, String uid) {
    return _postVotes
        .where('postId', isEqualTo: post.id)
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((event) {
      int upvoteCount = 0;
      int downvoteCount = 0;
      for (var doc in event.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['isUpvoted'] == true) {
          upvoteCount++;
        } else {
          downvoteCount++;
        }
      }
      return {
        'upvotes': upvoteCount,
        'downvotes': downvoteCount,
      };
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
  CollectionReference get _postVotes =>
      _firestore.collection(FirebaseConstants.postVoteCollection);
}
