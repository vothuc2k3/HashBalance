import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/providers/storage_repository_providers.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';
import 'package:hash_balance/models/poll_model.dart';
import 'package:hash_balance/models/poll_option_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:hash_balance/models/poll_option_vote_model.dart';
import 'package:tuple/tuple.dart';
import 'package:rxdart/rxdart.dart';
import 'package:logger/logger.dart';

final postRepositoryProvider = Provider((ref) {
  return PostRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    storageRepository: ref.watch(storageRepositoryProvider),
  );
});

class PostRepository {
  final FirebaseFirestore _firestore;
  final StorageRepository _storageRepository;
  final Logger _logger = Logger();

  PostRepository({
    required FirebaseFirestore firestore,
    required StorageRepository storageRepository,
  })  : _firestore = firestore,
        _storageRepository = storageRepository;

  //REFERENCE ALL THE POSTS
  CollectionReference get _posts =>
      _firestore.collection(FirebaseConstants.postsCollection);
  //REFERENCE ALL THE POLLS
  CollectionReference get _polls =>
      _firestore.collection(FirebaseConstants.pollsCollection);
  //REFERENCE ALL THE COMMENTS
  CollectionReference get _comments =>
      _firestore.collection(FirebaseConstants.commentsCollection);
  //REFERENCE ALL THE USERS
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);
  //REFERENCE ALL THE POST SHARES
  CollectionReference get _postShares =>
      _firestore.collection(FirebaseConstants.postShareCollection);
  //REFERENCE ALL THE POLL OPTIONS
  CollectionReference get _pollOptions =>
      _firestore.collection(FirebaseConstants.pollOptionsCollection);
  //REFERENCE ALL THE POLL OPTION VOTES
  CollectionReference get _pollOptionVotes =>
      _firestore.collection(FirebaseConstants.pollOptionVotesCollection);

  //CREATE A NEW POST
  Future<Either<Failures, void>> createPost(
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

  Stream<Map<String, dynamic>> getPostVoteCountAndStatus(
      Post post, String uid) async* {
    try {
      final upvoteDataStream = _posts
          .doc(post.id)
          .collection(FirebaseConstants.postVoteCollection)
          .where('isUpvoted', isEqualTo: true)
          .snapshots();

      final downvoteDataStream = _posts
          .doc(post.id)
          .collection(FirebaseConstants.postVoteCollection)
          .where('isUpvoted', isEqualTo: false)
          .snapshots();

      final userVoteStatusStream = _posts
          .doc(post.id)
          .collection(FirebaseConstants.postVoteCollection)
          .where('uid', isEqualTo: uid)
          .snapshots();

      await for (final upvoteSnapshot in upvoteDataStream) {
        final downvoteSnapshot = await downvoteDataStream.first;
        final voteStatusSnapshot = await userVoteStatusStream.first;

        final upvote = upvoteSnapshot.size;
        final downvote = downvoteSnapshot.size;

        String? userVoteStatus;
        if (voteStatusSnapshot.docs.isNotEmpty) {
          final voteData = voteStatusSnapshot.docs.first.data();
          userVoteStatus =
              voteData['isUpvoted'] == true ? 'upvoted' : 'downvoted';
        } else {
          userVoteStatus = null;
        }

        yield {
          'upvotes': upvote,
          'downvotes': downvote,
          'userVoteStatus': userVoteStatus,
        };
      }
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  Stream<Map<String, dynamic>> getPostVoteCountAndStatusStream(
      Post post, String uid) {
    return _posts.doc(post.id).snapshots().asyncMap(
      (event) async {
        final upvoteDataQuery = await _posts
            .doc(post.id)
            .collection(FirebaseConstants.postVoteCollection)
            .where('isUpvoted', isEqualTo: true)
            .get();
        final downvoteDataQuery = await _posts
            .doc(post.id)
            .collection(FirebaseConstants.postVoteCollection)
            .where('isUpvoted', isEqualTo: false)
            .get();
        final upvote = upvoteDataQuery.size;
        final downvote = downvoteDataQuery.size;
        final voteStatusSnapshot = await _posts
            .doc(post.id)
            .collection(FirebaseConstants.postVoteCollection)
            .where('uid', isEqualTo: uid)
            .get();
        String? userVoteStatus;
        if (voteStatusSnapshot.docs.isNotEmpty) {
          final voteData = voteStatusSnapshot.docs.first.data();
          userVoteStatus =
              voteData['isUpvoted'] == true ? 'upvoted' : 'downvoted';
        } else {
          userVoteStatus = null;
        }
        return {
          'upvotes': upvote,
          'downvotes': downvote,
          'userVoteStatus': userVoteStatus,
        };
      },
    );
  }

  //DELETE THE POST
  Future<Either<Failures, void>> deletePost(Post post, String uid) async {
    final batch = _firestore.batch();
    try {
      final postVotes = await _posts
          .doc(post.id)
          .collection(FirebaseConstants.postVoteCollection)
          .get();
      for (final postVote in postVotes.docs) {
        await postVote.reference.delete();
      }
      await _posts.doc(post.id).delete();

      await _storageRepository.deleteFile(
        path: 'posts/images/${post.id}',
      );
      await _storageRepository.deleteFile(
        path: 'posts/videos/${post.id}',
      );
      await batch.commit();
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<List<PostDataModel>> getPendingPosts({
    required String communityId,
  }) {
    return _posts
        .where('communityId', isEqualTo: communityId)
        .where('status', isEqualTo: 'Pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap(
      (event) async {
        List<PostDataModel> posts = [];
        if (event.docs.isNotEmpty) {
          for (var postDoc in event.docs) {
            final post = Post.fromMap(postDoc.data() as Map<String, dynamic>);
            final authorDoc = await _users.doc(post.uid).get();
            final author =
                UserModel.fromMap(authorDoc.data() as Map<String, dynamic>);
            posts.add(PostDataModel(post: post, author: author));
          }
          _logger.d('There are pending posts');
          return posts;
        } else {
          _logger.d('No pending posts');
          return [];
        }
      },
    );
  }

  //FETCH PIN POST
  Future<PostDataModel?> getCommunityPinnedPost(Community community) async {
    final pinnedPostDoc = await _posts
        .where('communityId', isEqualTo: community.id)
        .where('isPinned', isEqualTo: true)
        .get();
    if (pinnedPostDoc.docs.isNotEmpty) {
      final post =
          Post.fromMap(pinnedPostDoc.docs.first.data() as Map<String, dynamic>);
      final authorDoc = await _users.doc(post.uid).get();
      final author =
          UserModel.fromMap(authorDoc.data() as Map<String, dynamic>);
      return PostDataModel(post: post, author: author, community: community);
    } else {
      return null;
    }
  }

  // GET TOTAL COMMENTS COUNT OF A POST
  Future<int> getPostCommentCount(String postId) async {
    final querySnapshot =
        await _comments.where('postId', isEqualTo: postId).get();
    return querySnapshot.size;
  }

  //GET TOTAL SHARE COUNT OF A POST
  Future<int> getPostShareCount(String postId) async {
    final querySnapshot =
        await _postShares.where('postId', isEqualTo: postId).get();
    return querySnapshot.size;
  }

  Future<Either<Failures, void>> updatePostStatus(
      Post post, String status) async {
    try {
      await _posts.doc(post.id).update({
        'status': status,
        'createdAt': Timestamp.now(),
      });
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, void>> createPoll({
    required Poll poll,
    required List<PollOption> pollOptions,
  }) async {
    try {
      await _polls.doc(poll.id).set(poll.toMap());
      for (var option in pollOptions) {
        await _pollOptions.doc(option.id).set(option.toMap());
      }
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  // VOTE THE OPTION WITH TRANSACTION
  Future<void> voteOption({
    required PollOptionVote pollOptionVote,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final pollOptionVoteQuery = await _pollOptionVotes
            .where('pollOptionId', isEqualTo: pollOptionVote.pollOptionId)
            .where('uid', isEqualTo: pollOptionVote.uid)
            .get();
        if (pollOptionVoteQuery.docs.isNotEmpty) {
          final existingVoteRef = pollOptionVoteQuery.docs.first.reference;
          transaction.delete(existingVoteRef);
        } else {
          final newVoteRef = _pollOptionVotes.doc(pollOptionVote.id);
          transaction.set(newVoteRef, pollOptionVote.toMap());
        }
      });
    } on FirebaseException catch (e) {
      throw e.message!;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> deletePoll({required String pollId}) async {
    try {
      await _polls.doc(pollId).delete();
      await _pollOptions.doc(pollId).delete();
      final voteDocs =
          await _pollOptionVotes.where('pollId', isEqualTo: pollId).get();
      for (var voteDoc in voteDocs.docs) {
        await voteDoc.reference.delete();
      }
    } on FirebaseException catch (e) {
      throw e.message!;
    }
  }

  Stream<String?> getUserPollOptionVote({
    required String pollId,
    required String uid,
  }) {
    return _pollOptionVotes
        .where('pollId', isEqualTo: pollId)
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((event) {
      if (event.docs.isNotEmpty) {
        final voteData = event.docs.first.data() as Map<String, dynamic>;
        return voteData['pollOptionId'];
      } else {
        return null;
      }
    });
  }

  Stream<int> getPollOptionVotesCount({required String pollOptionId}) {
    return _pollOptionVotes
        .where('pollOptionId', isEqualTo: pollOptionId)
        .snapshots()
        .map((event) => event.size);
  }

  Stream<Tuple2<String?, int>> getPollOptionVotesCountAndUserVoteStatus({
    required String pollId,
    required String uid,
    required String optionId,
  }) {
    Stream<String?> getUserPollOptionVoteStream =
        getUserPollOptionVote(pollId: pollId, uid: uid);
    Stream<int> getPollOptionVotesCountStream =
        getPollOptionVotesCount(pollOptionId: optionId);

    return Rx.combineLatest2(
        getUserPollOptionVoteStream, getPollOptionVotesCountStream,
        (userPollOptionVote, pollOptionVotesCount) {
      return Tuple2(userPollOptionVote, pollOptionVotesCount);
    });
  }
}
