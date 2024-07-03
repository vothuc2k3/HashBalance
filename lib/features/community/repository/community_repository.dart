import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/core/common/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/community_membership_model.dart';
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
    return _communityMembership
        .where('uid', isEqualTo: uid)
        .snapshots()
        .asyncMap((event) async {
      final communities = <Community>[];
      for (var doc in event.docs) {
        final communityName =
            (doc.data() as Map<String, dynamic>)['communityName'] as String;
        final communitySnapshot = await _communities.doc(communityName).get();
        final data = communitySnapshot.data() as Map<String, dynamic>;
        communities.add(
          Community(
            id: data['id'] as String,
            name: data['name'] as String,
            profileImage: data['profileImage'] as String,
            bannerImage: data['bannerImage'] as String,
            type: data['type'] as String,
            containsExposureContents: data['containsExposureContents'] as bool,
            createdAt: data['createdAt'] as Timestamp,
          ),
        );
      }
      return communities;
    });
  }

  Stream<List<Community>> getMyCommunities(String uid) {
    return _communityMembership
        .where('uid', isEqualTo: uid)
        .where('role', isEqualTo: Constants.moderatorRole)
        .snapshots()
        .asyncMap((event) async {
      final communities = <Community>[];
      for (var doc in event.docs) {
        final communityName =
            (doc.data() as Map<String, dynamic>)['communityName'] as String;
        final communitySnapshot = await _communities.doc(communityName).get();
        final data = communitySnapshot.data() as Map<String, dynamic>;
        communities.add(
          Community(
            id: data['id'] as String,
            name: data['name'] as String,
            profileImage: data['profileImage'] as String,
            bannerImage: data['bannerImage'] as String,
            type: data['type'] as String,
            containsExposureContents: data['containsExposureContents'] as bool,
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
      return Community(
        name: data['name'] as String,
        profileImage: data['profileImage'] as String,
        bannerImage: data['bannerImage'] as String,
        createdAt: data['createdAt'] as Timestamp,
        type: data['type'] as String,
        containsExposureContents: data['containsExposureContents'] as bool,
        id: data['id'] as String,
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
  FutureVoid joinCommunity(CommunityMembership membership) async {
    try {
      await _communityMembership.doc(membership.id).set(membership.toMap());

      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //LET USER JOIN COMMUNITY
  FutureVoid leaveCommunity(String membershipId) async {
    try {
      await _communityMembership.doc(membershipId).delete();

      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //GET MOST JOINED COMMUNITIES
  Stream<List<Community>?> getTopCommunitiesList() {
    return _communities.snapshots().asyncMap((communitySnapshot) async {
      final communities = <Community>[];
      final communityCountMap = <String, int>{};

      final memberCountFutures = communitySnapshot.docs.map((doc) async {
        final communityName = doc.id;
        final communityData = doc.data() as Map<String, dynamic>;

        final memberCountSnapshot = await _communityMembership
            .where('communityName', isEqualTo: communityName)
            .get();
        final memberCount = memberCountSnapshot.size;
        communityCountMap[communityName] = memberCount;

        communities.add(
          Community(
            id: communityData['id'] as String,
            name: communityData['name'] as String,
            profileImage: communityData['profileImage'] as String,
            bannerImage: communityData['bannerImage'] as String,
            type: communityData['type'] as String,
            createdAt: communityData['createdAt'] as Timestamp,
            containsExposureContents:
                communityData['containsExposureContents'] as bool,
          ),
        );
      });

      await Future.wait(memberCountFutures);

      communities.sort((a, b) =>
          communityCountMap[b.id]!.compareTo(communityCountMap[a.id]!));

      return communities;
    });
  }

  //CHECK IF THE USER IS MEMBER OF COMMUNITY
  Stream<bool> getMemberStatus(String membershipId) {
    try {
      final snapshot = _communityMembership.doc(membershipId).snapshots();
      return snapshot.map((docSnapshot) {
        return docSnapshot.exists;
      });
    } on FirebaseException catch (e) {
      return Stream.error(Failures(e.message!));
    } catch (e) {
      return Stream.error(Failures(e.toString()));
    }
  }

  //GET MEMBER COUNT OF COMMUNITY
  Stream<int> getCommunityMemberCount(String communityName) {
    return _communityMembership
        .where('communityName', isEqualTo: communityName)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Stream<bool> getModeratorStatus(String membershipId) {
    return _communityMembership.doc(membershipId).snapshots().map((event) {
      if(event.data() == null){
        return false;
      }
      final data = event.data() as Map<String, dynamic>;
      final role = data['role'] as String;
      if (role == Constants.moderatorRole) {
        return true;
      }
      return false;
    });
  }

  //GET THE COMMUNITIES DATA
  CollectionReference get _communities =>
      _firestore.collection(FirebaseConstants.communitiesCollection);
  //GET THE COMMUNITIES DATA
  CollectionReference get _communityMembership =>
      _firestore.collection(FirebaseConstants.communityMembershipCollection);
}
