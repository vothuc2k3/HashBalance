import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/conbined_models/newsfeed_data_model.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';
import 'package:hash_balance/models/poll_model.dart';
import 'package:hash_balance/models/poll_option_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:hash_balance/models/conbined_models/poll_data_model.dart';

final newsfeedRepositoryProvider = Provider((ref) {
  return NewsfeedRepository(firestore: ref.watch(firebaseFirestoreProvider));
});

class NewsfeedRepository {
  final FirebaseFirestore _firestore;

  NewsfeedRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  //REFERENCE ALL THE USERS
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);
  //REFERENCE ALL THE COMMUNITIES
  CollectionReference get _communities =>
      _firestore.collection(FirebaseConstants.communitiesCollection);
  //REFERENCE THE POSTS DATA
  CollectionReference get _posts =>
      _firestore.collection(FirebaseConstants.postsCollection);
  //REFERENCE THE COMMUNITIES DATA
  CollectionReference get _communityMembership =>
      _firestore.collection(FirebaseConstants.communityMembershipCollection);
  //REFERENCE THE POLLS DATA
  CollectionReference get _polls =>
      _firestore.collection(FirebaseConstants.pollsCollection);
  //REFERENCE THE POLLS DATA
  CollectionReference get _pollOptions =>
      _firestore.collection(FirebaseConstants.pollOptionsCollection);

  Stream<List<NewsfeedCombinedModel>> getNewsfeedPosts({
    required String uid,
  }) {
    return _communityMembership
        .where('uid', isEqualTo: uid)
        .snapshots()
        .asyncMap((event) async {
      // Initialize lists for newsfeed data
      List<NewsfeedCombinedModel> newsfeedDataList = [];
      final List<PostDataModel> postDataList = [];
      final List<PollDataModel> pollDataList = [];

      // Fetch community IDs
      final communityIds =
          event.docs.map((doc) => doc['communityId'] as String).toList();

      // Fetch posts and polls for the given community IDs
      final postsQuery = await _posts
          .where('communityId', whereIn: communityIds)
          .where('status', isEqualTo: 'Approved')
          .get();
      final pollsQuery =
          await _polls.where('communityId', whereIn: communityIds).get();

      // Prepare lists to hold the posts and polls
      List<Post> posts = [];
      List<Poll> polls = [];

      // Extract posts from the query results
      for (var post in postsQuery.docs) {
        posts.add(Post.fromMap(post.data() as Map<String, dynamic>));
      }

      // Create PostDataModel instances and add them to postDataList
      for (var post in posts) {
        final authorDoc = await _users.doc(post.uid).get();
        final author =
            UserModel.fromMap(authorDoc.data() as Map<String, dynamic>);
        final communityDoc = await _communities.doc(post.communityId).get();
        final community =
            Community.fromMap(communityDoc.data() as Map<String, dynamic>);
        postDataList.add(
          PostDataModel(post: post, author: author, community: community),
        );
      }

      for (var poll in pollsQuery.docs) {
        polls.add(Poll.fromMap(poll.data() as Map<String, dynamic>));
      }

      for (var poll in polls) {
        final authorDoc = await _users.doc(poll.uid).get();
        final author =
            UserModel.fromMap(authorDoc.data() as Map<String, dynamic>);
        final communityDoc = await _communities.doc(poll.communityId).get();
        final community =
            Community.fromMap(communityDoc.data() as Map<String, dynamic>);
        final optionsQuery =
            await _pollOptions.where('pollId', isEqualTo: poll.id).get();
        List<PollOption> options = optionsQuery.docs
            .map((option) =>
                PollOption.fromMap(option.data() as Map<String, dynamic>))
            .toList();
        pollDataList.add(
          PollDataModel(
            poll: poll,
            author: author,
            community: community,
            options: options,
          ),
        );
      }

      // Combine posts and polls into NewsfeedCombinedModel and add to the newsfeedDataList
      for (var postData in postDataList) {
        newsfeedDataList.add(NewsfeedCombinedModel(post: postData, poll: null));
      }

      for (var pollData in pollDataList) {
        newsfeedDataList.add(NewsfeedCombinedModel(post: null, poll: pollData));
      }
      newsfeedDataList.sort((a, b) {
        final postDateA = a.post?.post.createdAt ?? Timestamp(0, 0);
        final pollDateA = a.poll?.poll.createdAt ?? Timestamp(0, 0);
        final postDateB = b.post?.post.createdAt ?? Timestamp(0, 0);
        final pollDateB = b.poll?.poll.createdAt ?? Timestamp(0, 0);

        return pollDateB.toDate().compareTo(pollDateA.toDate()) +
            postDateB.toDate().compareTo(postDateA.toDate());
      });

      return newsfeedDataList;
    });
  }

  Stream<List<PollDataModel>> getNewsfeedPolls({
    required String uid,
  }) {
    return _communityMembership
        .where('uid', isEqualTo: uid)
        .snapshots()
        .asyncMap((event) async {
      final List<PollDataModel> pollDataList = [];
      final List<Poll> polls = [];
      final List<PollOption> options = [];

      final communityIds =
          event.docs.map((doc) => doc['communityId'] as String).toList();
      final pollsQuery =
          await _polls.where('communityId', whereIn: communityIds).get();
      for (var poll in pollsQuery.docs) {
        polls.add(Poll.fromMap(poll.data() as Map<String, dynamic>));
      }
      for (var poll in polls) {
        final authorDoc = await _users.doc(poll.uid).get();
        final author =
            UserModel.fromMap(authorDoc.data() as Map<String, dynamic>);
        final communityDoc = await _communities.doc(poll.communityId).get();
        final community =
            Community.fromMap(communityDoc.data() as Map<String, dynamic>);
        final optionsQuery =
            await _pollOptions.where('pollId', isEqualTo: poll.id).get();
        for (var option in optionsQuery.docs) {
          options
              .add(PollOption.fromMap(option.data() as Map<String, dynamic>));
        }
        pollDataList.add(PollDataModel(
            poll: poll,
            author: author,
            community: community,
            options: options));
      }

      return pollDataList;
    });
  }
}
