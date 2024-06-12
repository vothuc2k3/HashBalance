import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/constants/firebase_constants.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/user_model.dart';

final searchRepositoryProvider = Provider(
  (ref) {
    return SearchRepository(
      firestore: ref.watch(firebaseFirestoreProvider),
    );
  },
);

class SearchRepository {
  final FirebaseFirestore _firestore;

  SearchRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  Stream<List<dynamic>> search(String query) {
    final streamController = StreamController<List<dynamic>>();
    if (query.isEmpty) {
      return const Stream.empty();
    }
    if (query.startsWith('#=')) {
      String communityQuery = query.substring(2);
      return _communities
          .where(
            'name',
            isGreaterThanOrEqualTo: communityQuery.isEmpty ? 0 : communityQuery,
            isLessThan: communityQuery.isEmpty
                ? null
                : communityQuery.substring(0, communityQuery.length - 1) +
                    String.fromCharCode(
                        communityQuery.codeUnitAt(communityQuery.length - 1) +
                            1),
          )
          .snapshots()
          .map(
        (event) {
          List<Community> communities = [];
          for (var doc in event.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final members = (data['members'] as List?)?.cast<String>() ?? [];
            final moderators = (data['mods'] as List?)?.cast<String>() ?? [];
            communities.add(
              Community(
                id: data['id'] as String,
                name: data['name'] as String,
                profileImage: data['profileImage'] as String,
                bannerImage: data['bannerImage'] as String,
                type: data['type'] as String,
                containsExposureContents:
                    data['containsExposureContents'] as bool,
                members: members,
                moderators: moderators,
                createdAt: data['createdAt'] as Timestamp,
              ),
            );
          }
          return communities;
        },
      );
    } else if (query.startsWith('#')) {
      String userQuery = query.substring(1);
      return _user
          .where(
            'name',
            isGreaterThanOrEqualTo: userQuery.isEmpty ? 0 : userQuery,
            isLessThan: userQuery.isEmpty
                ? null
                : userQuery.substring(0, userQuery.length - 1) +
                    String.fromCharCode(
                        userQuery.codeUnitAt(userQuery.length - 1) + 1),
          )
          .snapshots()
          .map(
        (event) {
          List<UserModel> users = [];
          for (var doc in event.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final achivements =
                (data['achivements'] as List?)?.cast<String>() ?? [];
            final friends = (data['friends'] as List?)?.cast<String>() ?? [];
            final followers =
                (data['followers'] as List?)?.cast<String>() ?? [];
            users.add(
              UserModel(
                name: data['name'] as String,
                profileImage: data['profileImage'] as String,
                bannerImage: data['bannerImage'] as String,
                email: data['email'] as String,
                uid: data['uid'] as String,
                isAuthenticated: data['isAuthenticated'] as bool,
                activityPoint: data['activityPoint'] as int,
                achivements: achivements,
                friends: friends,
                createdAt: data['createdAt'] as Timestamp,
                isRestricted: data['isRestricted'] as bool,
                followers: followers,
              ),
            );
          }
          return users;
        },
      );
    } else {
      streamController.close();
    }
    return streamController.stream;
  }

  CollectionReference get _communities =>
      _firestore.collection(FirebaseConstants.communitiesCollection);
  CollectionReference get _user =>
      _firestore.collection(FirebaseConstants.usersCollection);
}
