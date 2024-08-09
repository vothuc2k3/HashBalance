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

  //GET THE COMMUNITIES DATA
  CollectionReference get _communities =>
      _firestore.collection(FirebaseConstants.communitiesCollection);
  //GET THE COMMUNITIES DATA
  CollectionReference get _communityMembership =>
      _firestore.collection(FirebaseConstants.communityMembershipCollection);

  //CREATE A WHOLE NEW COMMUNITY
  FutureVoid createCommunity(Community community) async {
    try {
      var communityDoc = await _communities.doc(community.id).get();

      if (communityDoc.exists) {
        throw 'The name is already exists!';
      }
      return right(
        _communities.doc(community.id).set(community.toMap()),
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
        final communityId =
            (doc.data() as Map<String, dynamic>)['communityId'] as String;
        final communitySnapshot = await _communities.doc(communityId).get();
        final data = communitySnapshot.data() as Map<String, dynamic>;
        communities.add(
          Community.fromMap(data),
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
        final communityId =
            (doc.data() as Map<String, dynamic>)['communityId'] as String;
        final communitySnapshot = await _communities.doc(communityId).get();
        final data = communitySnapshot.data() as Map<String, dynamic>;
        communities.add(Community.fromMap(data));
      }
      return communities;
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
        await _communities.doc(community.id).update(communityAfterCast),
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
        final communityId = doc.id;
        final communityData = doc.data() as Map<String, dynamic>;

        final memberCountSnapshot = await _communityMembership
            .where('communityId', isEqualTo: communityId)
            .get();
        final memberCount = memberCountSnapshot.size;
        communityCountMap[communityId] = memberCount;

        communities.add(
          Community.fromMap(communityData),
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
  Stream<int> getCommunityMemberCount(String communityId) {
    return _communityMembership
        .where('communityId', isEqualTo: communityId)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Stream<bool> getModeratorStatus(String membershipId) {
    return _communityMembership.doc(membershipId).snapshots().map((event) {
      if (event.data() == null) {
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

  Stream<Community?> getCommunityById(String communityId) {
    return _communities.doc(communityId).snapshots().map(
      (event) {
        final data = event.data() as Map<String, dynamic>;
        return Community.fromMap(data);
      },
    );
  }
}
