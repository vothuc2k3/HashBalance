import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
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
    if (query.isEmpty) {
      return Stream.value([]);
    }

    if (query.startsWith('#=')) {
      String communityQuery = query.substring(2);
      String? communityQueryEnd = communityQuery.isEmpty
          ? null
          : communityQuery.substring(0, communityQuery.length - 1) +
              String.fromCharCode(
                  communityQuery.codeUnitAt(communityQuery.length - 1) + 1);

      return _communities
          .where('name',
              isGreaterThanOrEqualTo: communityQuery,
              isLessThan: communityQueryEnd)
          .snapshots()
          .map((event) {
        return event.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Community.fromMap(data);
        }).toList();
      }).handleError((error) {
        return [];
      });
    } else if (query.startsWith('#')) {
      String userQuery = query.substring(1);
      String? userQueryEnd = userQuery.isEmpty
          ? null
          : userQuery.substring(0, userQuery.length - 1) +
              String.fromCharCode(
                  userQuery.codeUnitAt(userQuery.length - 1) + 1);

      return _user
          .where('name',
              isGreaterThanOrEqualTo: userQuery, isLessThan: userQueryEnd)
          .snapshots()
          .map((event) {
        return event.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return UserModel.fromMap(data);
        }).toList();
      }).handleError((error) {
        return [];
      });
    } else {
      return Stream.value([]);
    }
  }

  CollectionReference get _communities =>
      _firestore.collection(FirebaseConstants.communitiesCollection);
  CollectionReference get _user =>
      _firestore.collection(FirebaseConstants.usersCollection);
}
