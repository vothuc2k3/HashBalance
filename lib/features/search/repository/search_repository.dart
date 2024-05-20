import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/constants/firebase_constants.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/models/community_model.dart';

final searchRepositoryProvider = Provider(
  (ref) {
    return SearchRepository(
      firestore: ref.watch(firebaseFireStoreProvider),
    );
  },
);

class SearchRepository {
  final FirebaseFirestore _firestore;

  SearchRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  Stream<List<Community>> search(String query) {
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
            final mods = (data['mods'] as List?)?.cast<String>() ?? [];
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
                mods: mods,
              ),
            );
          }
          return communities;
        },
      );
    } else {
      return _communities
          .where(
            'name',
            isGreaterThanOrEqualTo: query.isEmpty ? 0 : query,
            isLessThan: query.isEmpty
                ? null
                : query.substring(0, query.length - 1) +
                    String.fromCharCode(query.codeUnitAt(query.length - 1) + 1),
          )
          .snapshots()
          .map(
        (event) {
          List<Community> communities = [];
          for (var doc in event.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final members = (data['members'] as List?)?.cast<String>() ?? [];
            final mods = (data['mods'] as List?)?.cast<String>() ?? [];
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
                mods: mods,
              ),
            );
          }
          return communities;
        },
      );
    }
  }

  CollectionReference get _communities =>
      _firestore.collection(FirebaseConstants.communitiesCollection);
}
