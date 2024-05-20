import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/common/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/community_model.dart';

final gamingCommunityRepositoryProvider = Provider((ref) {
  return GamingCommunityRepository(
      firestore: ref.watch(firebaseFireStoreProvider));
});

class GamingCommunityRepository {
  final FirebaseFirestore _firestore;

  GamingCommunityRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  FutureVoid createGamingCommunity(Community community) async {
    try {
      var communityDoc = await _communities.doc(community.name).get();
      if (communityDoc.exists) {
        throw 'The name is already exists!';
      }
      return right(
        _communities.doc(community.name).set(community.toMap()),
      );
    } on FirebaseException catch (e) {
      return left(
        Failures(e.message!),
      );
    } catch (e) {
      return left(
        Failures(
          e.toString(),
        ),
      );
    }
  }

  //get the communities by uid
  Stream<List<Community>> getUserCommunities(String uid) {
    return _communities
        .where('members', arrayContains: uid)
        .snapshots()
        .map((event) {
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
            containsExposureContents: data['containsExposureContents'] as bool,
            members: members,
            mods: mods,
          ),
        );
      }
      return communities;
    });
  }

  //get the community data by the name of its
  // Stream<Community> getCommunityByName(String name) {
  //   return _communities.where(name).snapshots().map(
  //     (community) {
  //       final doc = community.docs.first;
  //       final data = doc.data() as Map<String, dynamic>;
  //       return Community(
  //         id: data['id'] as String,
  //         name: data['name'] as String,
  //         profileImage: data['profileImage'] as String,
  //         bannerImage: data['bannerImage'] as String,
  //         type: data['type'] as String,
  //         containsExposureContents: data['containsExposureContents'] as bool,
  //         members: (data['members'] as List).cast<String>(),
  //         mods: (data['mods'] as List).cast<String>(),
  //       );
  //     },
  //   );
  // }
  Stream<Community> getCommunityByName(String name) {
    return _communities.doc(name).snapshots().map(
          (event) => Community.fromMap(event.data() as Map<String, dynamic>),
        );
  }

  //submit the edit data to Firebase
  FutureVoid editCommunityProfileOrBannerImage(Community community) async {
    try {
      final Map<String, dynamic> communityAfterCast = {
        'id': community.id,
        'name': community.name,
        'profileImage': community.profileImage,
        'bannerImage': community.bannerImage,
        'type': community.type,
        'containsExposureContents': community.containsExposureContents,
        'members': List<String>.from(community.members),
        'mods': List<String>.from(community.mods),
      };

      return right(
        await _communities.doc(community.name).update(communityAfterCast),
      );
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<List<Community>> searchCommunity(String query) {
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

  CollectionReference get _communities =>
      _firestore.collection(FirebaseConstants.communitiesCollection);
}
