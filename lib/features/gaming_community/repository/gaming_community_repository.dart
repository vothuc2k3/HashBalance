import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/common/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/gaming_community_model.dart';

final gamingCommunityRepositoryProvider = Provider((ref) {
  return GamingCommunityRepository(
      firestore: ref.watch(firebaseFireStoreProvider));
});

class GamingCommunityRepository {
  FirebaseFirestore _firestore;

  GamingCommunityRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  FutureVoid createGamingCommunity(GamingCommunityModel community) async {
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

  Stream<List<GamingCommunityModel>> getUserCommunities(String uid) {
    return _communities
        .where('members', arrayContains: uid)
        .snapshots()
        .map((event) {
      List<GamingCommunityModel> communities = [];
      for (var doc in event.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final members = (data['members'] as List?)?.cast<String>() ?? [];
        final mods = (data['mods'] as List?)?.cast<String>() ?? [];
        communities.add(
          GamingCommunityModel(
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

  CollectionReference get _communities =>
      _firestore.collection(FirebaseConstants.communitiesCollection);
}
