import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/providers/storage_repository_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/post_vote_model.dart';

final postRepositoryProvider = Provider((ref) {
  return PostRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    storageRepository: ref.watch(storageRepositoryProvider),
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
  //REFERENCE ALL THE COMMENTS
  CollectionReference get _comments =>
      _firestore.collection(FirebaseConstants.commentsCollection);
  //REFERENCE ALL THE USERS
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);

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

  // VOTE THE POST
  Future<void> votePost(PostVote postVoteModel, Post post) async {
    final batch = _firestore.batch();
    try {
      final postVoteCollection =
          _posts.doc(post.id).collection(FirebaseConstants.postVoteCollection);
      final querySnapshot = await postVoteCollection
          .where('uid', isEqualTo: postVoteModel.uid)
          .get();

      if (querySnapshot.docs.isEmpty) {
        final postVoteRef = postVoteCollection.doc(postVoteModel.id);
        batch.set(postVoteRef, postVoteModel.toMap());
        if (postVoteModel.isUpvoted) {
          batch.update(_posts.doc(post.id), {
            'upvoteCount': FieldValue.increment(1),
          });
        } else {
          batch.update(_posts.doc(post.id), {
            'downvoteCount': FieldValue.increment(1),
          });
        }
      } else {
        final data = querySnapshot.docs.first.data();
        final postVoteModelId = querySnapshot.docs.first.id;
        final isAlreadyUpvoted = data['isUpvoted'] as bool;
        final doWantToUpvote = postVoteModel.isUpvoted;

        if (doWantToUpvote == isAlreadyUpvoted) {
          batch.delete(postVoteCollection.doc(postVoteModelId));
          if (doWantToUpvote) {
            batch.update(_posts.doc(post.id), {
              'upvoteCount': FieldValue.increment(-1),
            });
          } else {
            batch.update(_posts.doc(post.id), {
              'downvoteCount': FieldValue.increment(-1),
            });
          }
        } else {
          batch.update(
              postVoteCollection.doc(postVoteModelId), postVoteModel.toMap());
          if (doWantToUpvote) {
            batch.update(_posts.doc(post.id), {
              'upvoteCount': FieldValue.increment(1),
              'downvoteCount': FieldValue.increment(-1),
            });
          } else {
            batch.update(_posts.doc(post.id), {
              'upvoteCount': FieldValue.increment(-1),
              'downvoteCount': FieldValue.increment(1),
            });
          }
        }
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  //CHECK VOTE STATUS OF A USER TOWARDS A POST
  Stream<bool?> getPostVoteStatus(Post post, String uid) {
    try {
      return _posts
          .doc(post.id)
          .collection(FirebaseConstants.postVoteCollection)
          .where('uid', isEqualTo: uid)
          .snapshots()
          .map((event) {
        if (event.docs.isEmpty) {
          return null;
        }
        bool isUpvoted = true;
        for (var doc in event.docs) {
          final data = doc.data();
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
    final batch = _firestore.batch();
    try {
      batch.delete(_posts.doc(post.id));
      await batch.commit();
      return right(null);
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
        communityPosts.add(
          Post.fromMap(doc.data() as Map<String, dynamic>),
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
          pendingPosts.add(
            Post.fromMap(doc.data() as Map<String, dynamic>),
          );
        }
        return pendingPosts;
      },
    );
  }

  Future<Either<Failures, Post?>> fetchPostByPostId(String postId) async {
    try {
      final postDoc = await _posts.doc(postId).get();
      if (postDoc.exists) {
        return right(Post.fromMap(postDoc.data() as Map<String, dynamic>));
      } else {
        return right(null);
      }
    } on FirebaseException catch (e) {  
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  // GET TOTAL COMMENTS COUNT OF A POST
  Stream<int> getPostCommentCount(String postId) {
    return _comments
        .where('postId', isEqualTo: postId)
        .snapshots()
        .map((event) {
      return event.size;
    });
  }
}
