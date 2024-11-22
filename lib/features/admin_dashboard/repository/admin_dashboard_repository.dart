
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart' as dio;

final adminDashboardRepositoryProvider = Provider((ref) =>
    AdminDashboardRepository(firestore: ref.watch(firebaseFirestoreProvider)));

class AdminDashboardRepository {
  final FirebaseFirestore _firestore;

  AdminDashboardRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  //REFERENCE ALL THE USERS
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);
  //REFERENCE ALL THE POSTS
  CollectionReference get _posts =>
      _firestore.collection(FirebaseConstants.postsCollection);
  //REFERENCE ALL THE COMMENTS
  CollectionReference get _comments =>
      _firestore.collection(FirebaseConstants.commentsCollection);
  //REFERENCE ALL THE REPORTS
  CollectionReference get _reports =>
      _firestore.collection(FirebaseConstants.reportCollection);

  Stream<int> getUsersCount() {
    return _users.snapshots().map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getPostsCount() {
    return _posts.snapshots().map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getCommentsCount() {
    return _comments.snapshots().map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getReportsCount() {
    return _reports.snapshots().map((snapshot) => snapshot.docs.length);
  }

  Future<List<Map<String, dynamic>>> getTrendingHashtags() async {
    try {
      final querySnapshot = await _posts.get();

      final Map<String, int> hashtagCounts = {};

      for (var doc in querySnapshot.docs) {
        final content = doc.data() as Map<String, dynamic>;
        final contentString = content['content'] as String? ?? '';

        final hashtags = RegExp(r"#\w+")
            .allMatches(contentString)
            .map((match) => match.group(0)!)
            .toList();

        for (var hashtag in hashtags) {
          hashtagCounts[hashtag] = (hashtagCounts[hashtag] ?? 0) + 1;
        }
      }

      final trendingHashtags = hashtagCounts.entries
          .map((entry) => {"tag": entry.key, "count": entry.value})
          .toList();

      trendingHashtags
          .sort((a, b) => (b["count"] as int).compareTo(a["count"] as int));

      Logger().d(trendingHashtags.toString());
      return trendingHashtags;
    } on FirebaseException catch (e) {
      throw Failures(e.message ?? "Unknown error");
    }
  }

  Future<List<Map<String, dynamic>>> getTopActiveUsers() async {
    try {
      final querySnapshot = await _users
          .orderBy('activityPoint', descending: true)
          .limit(5)
          .get();

      return Future.wait(querySnapshot.docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;
        final uid = data['uid'] as String;

        final postDocs = await _posts.where('uid', isEqualTo: uid).get();
        final commentDocs = await _comments.where('uid', isEqualTo: uid).get();

        return {
          "name": data["name"] ?? "Unknown",
          "profileImage": data["profileImage"] ?? "",
          "posts": postDocs.docs.length,
          "comments": commentDocs.docs.length,
          "activityPoint": data["activityPoint"] ?? 0,
        };
      }).toList());
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  Future<Either<Failures, void>> disableUserAccount(String uid) async {
    try {
      final url = '${Constants.domain}/disableUserAccount';
      final response = await dio.Dio().post(
        url,
        data: {"uid": uid},
      );
      if (response.statusCode == 200) {
        return right(null);
      } else {
        return left(Failures("Failed to disable user account"));
      }
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }
}
