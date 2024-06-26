import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/common/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/community_model.dart';

final communityRepositoryProvider = Provider((ref) {
  return CommunityRepository(firestore: ref.watch(firebaseFirestoreProvider));
});

class CommunityRepository {
  final FirebaseFirestore _firestore;

  CommunityRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  //CREATE A WHOLE NEW COMMUNITY
  FutureVoid createCommunity(Community community) async {
    try {
      var communityDoc = await _communities.doc(community.name).get();

      if (communityDoc.exists) {
        throw 'The name is already exists!';
      }
      return right(
        _communities.doc(community.name).set(community.toMap()),
      );
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //GET THE COMMUNITIES BY CURRENT USER
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
            moderators: mods,
            createdAt: data['createdAt'] as Timestamp,
          ),
        );
      }
      return communities;
    });
  }

  Stream<List<Community>> getMyCommunities(String uid) {
    return _communities
        .where('moderators', arrayContains: uid)
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
            moderators: mods,
            createdAt: data['createdAt'] as Timestamp,
          ),
        );
      }
      return communities;
    });
  }

  //GET THE COMMUNITY BY NAME
  Stream<Community> getCommunityByName(String name) {
    return _communities.doc(name).snapshots().map((event) {
      final data = event.data() as Map<String, dynamic>;
      final members = (data['members'] as List?)?.cast<String>() ?? [];
      final moderators = (data['moderators'] as List?)?.cast<String>() ?? [];
      return Community(
        name: data['name'] as String,
        profileImage: data['profileImage'] as String,
        bannerImage: data['bannerImage'] as String,
        createdAt: data['createdAt'] as Timestamp,
        type: data['type'] as String,
        containsExposureContents: data['containsExposureContents'] as bool,
        moderators: moderators,
        members: members,
        id: '',
      );
    });
  }

  //EDIT COMMUNITY VISUAL
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
        'mods': List<String>.from(community.moderators),
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

  //LET USER JOIN COMMUNITY
  FutureVoid joinCommunity(String uid, String communityName) async {
    try {
      return right(_communities.doc(communityName).update({
        'members': FieldValue.arrayUnion([uid]),
      }));
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //LET USER JOIN COMMUNITY
  FutureVoid leaveCommunity(String uid, String communityName) async {
    try {
      return right(_communities.doc(communityName).update({
        'members': FieldValue.arrayRemove([uid]),
      }));
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<List<Community>?> getTopCommunitiesList() {
    return _communities.snapshots().map(
      (snapshot) {
        if (snapshot.docs.isEmpty) {
          return null;
        } else {
          return snapshot.docs
              .map((doc) => Community.fromFirestore(doc))
              .toList();
        }
      },
    ).map(
      (communities) {
        if (communities == null) {
          return null;
        } else {
          communities.sort((a, b) => b.membersCount.compareTo(a.membersCount));
          return communities;
        }
      },
    );
  }

  //GET THE COMMUNITIES DATA
  CollectionReference get _communities =>
      _firestore.collection(FirebaseConstants.communitiesCollection);
}
