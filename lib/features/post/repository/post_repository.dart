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

  //REFERENCE ALL THE POSTS
  CollectionReference get _posts =>
      _firestore.collection(FirebaseConstants.postsCollection);
  //REFERENCE ALL THE USERS
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);
  //REFERENCE ALL THE POSTS
  CollectionReference get _postVotes =>
      _firestore.collection(FirebaseConstants.postVoteCollection);

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
  Future<void> votePost(PostVote postVoteModel, Post post) async {
    try {
      final querySnapshot = await _postVotes
          .where('postId', isEqualTo: postVoteModel.postId)
          .where('uid', isEqualTo: postVoteModel.uid)
          .get();

      if (querySnapshot.docs.isEmpty) {
        await _postVotes.doc(postVoteModel.id).set(postVoteModel.toMap());
        if (postVoteModel.isUpvoted) {
          await _posts
              .doc(post.id)
              .update({'upvoteCount': FieldValue.increment(1)});
        } else {
          await _posts
              .doc(post.id)
              .update({'upvoteCount': FieldValue.increment(-1)});
        }
      } else {
        final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
        final postVoteModelId = querySnapshot.docs.first.id;
        final isAlreadyUpvoted = data['isUpvoted'] as bool;
        final doWantToUpvote = postVoteModel.isUpvoted;

        if (doWantToUpvote == isAlreadyUpvoted) {
          // Remove the vote
          await _postVotes.doc(postVoteModelId).delete();
          if (doWantToUpvote) {
            await _posts
                .doc(post.id)
                .update({'upvoteCount': FieldValue.increment(-1)});
          } else {
            await _posts
                .doc(post.id)
                .update({'upvoteCount': FieldValue.increment(1)});
          }
        } else {
          // Update the vote
          await _postVotes.doc(postVoteModelId).update(postVoteModel.toMap());
          if (doWantToUpvote) {
            await _posts.doc(post.id).update({
              'upvoteCount': FieldValue.increment(1),
              'downvoteCount': FieldValue.increment(-1)
            });
          } else {
            await _posts.doc(post.id).update({
              'upvoteCount': FieldValue.increment(-1),
              'downvoteCount': FieldValue.increment(1)
            });
          }
        }
      }
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  //CHECK VOTE STATUS OF A USER TOWARDS A POST
  Stream<bool?> getPostVoteStatus(Post post, String uid) {
    try {
      return _postVotes
          .where('postId', isEqualTo: post.id)
          .where('uid', isEqualTo: uid)
          .snapshots()
          .map((event) {
        if (event.docs.isEmpty) {
          return null;
        }
        bool isUpvoted = true;
        for (var doc in event.docs) {
          final data = doc.data() as Map<String, dynamic>;
          isUpvoted = data['isUpvoted'];
          break;
        }
        return isUpvoted;
      });
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  //GET VOTE COUNT OF A POST
  Stream<Map<String, int>> getPostVoteCount(Post post) {
    return _posts.doc(post.id).snapshots().map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'upvotes': data['upvoteCount'],
        'downvotes': data['downvoteCount'],
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
      return Post.fromMap(data);
    });
  }

  //FETCH POSTS BY COMMUNITIES
  Stream<List<Post>?> fetchCommunityPosts(String communityId) {
    return _posts
        .where('communityId', isEqualTo: communityId)
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
            communityId: postData['communityId'] as String,
            uid: postData['uid'] as String,
            status: postData['status'] as String,
            upvoteCount: postData['upvoteCount'] as int,
            downvoteCount: postData['downvoteCount'] as int,
            createdAt: postData['createdAt'] as Timestamp,
            id: postData['id'] as String,
          ),
        );
      }
      return communityPosts;
    });
  }

  Stream<List<Post>?> getPendingPosts(String communityId) {
    return _posts
        .where('communityId', isEqualTo: communityId)
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .map(
      (event) {
        if (event.docs.isEmpty) {
          return null;
        }
        final pendingPosts = <Post>[];
        for (final doc in event.docs) {
          final postData = doc.data() as Map<String, dynamic>;
          var content = postData['content'] ?? '';
          var image = postData['image'] ?? '';
          var video = postData['video'] ?? '';
          pendingPosts.add(
            Post(
              video: video as String,
              image: image as String,
              content: content as String,
              communityId: postData['communityId'] as String,
              uid: postData['uid'] as String,
              status: postData['status'] as String,
              upvoteCount: postData['upvoteCount'] as int,
              downvoteCount: postData['downvoteCount'] as int,
              createdAt: postData['createdAt'] as Timestamp,
              id: postData['id'] as String,
            ),
          );
        }
        return pendingPosts;
      },
    );
  }
}
