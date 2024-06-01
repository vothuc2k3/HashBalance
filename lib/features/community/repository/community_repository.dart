import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/common/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/community.dart';
import 'package:hash_balance/models/community_membership.dart';
import 'package:hash_balance/models/community_moderators.dart';

final communityRepositoryProvider = Provider((ref) {
  return CommunityRepository(firestore: ref.watch(firebaseFirestoreProvider));
});

class CommunityRepository {
  final FirebaseFirestore _firestore;

  CommunityRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  List<Map<String, dynamic>> _membershipsList = [];
  List<Map<String, dynamic>> _moderatorsList = [];

  //CREATE A WHOLE NEW COMMUNITY
  FutureVoid createCommunity(
    Community community,
    CommunityMembership membership,
    CommunityModerators moderator,
    String uid,
  ) async {
    try {
      var communityDoc = await _communities.doc(community.name).get();
      if (communityDoc.exists) {
        throw 'The name is already exists!';
      }
      right(
        await _communities.doc(community.name).set(community.toMap()),
      );
      final id = uid + community.name;
      right(await _moderators.doc(id).set(membership.toMap()));
      right(await _membership.doc(id).set(membership.toMap()));
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //GET THE COMMUNITIES BY CURRENT USER
  Stream<List<Community>> getUserCommunities(String uid) {
    return _membership
        .where('uid', isEqualTo: uid)
        .snapshots()
        .asyncMap((event) async {
      final communitiesName =
          event.docs.map((doc) => doc['communityName'] as String).toList();

      if (communitiesName.isEmpty) {
        return [];
      }

      final communitySnapshots = await _communities
          .where(FieldPath.documentId, whereIn: communitiesName)
          .get();
      return communitySnapshots.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Community(
          name: data['name'] as String,
          profileImage: data['profileImage'] as String,
          bannerImage: data['bannerImage'] as String,
          type: data['type'] as String,
          containsExposureContents: data['containsExposureContents'] as bool,
          membersCount: data['membersCount'] as int,
          createdAt: data['createdAt'] as Timestamp,
        );
      }).toList();
    });
  }

  //GET THE COMMUNITY BY NAME
  Stream<Community> getCommunityByName(String name) {
    return _communities.doc(name).snapshots().map(
          (event) => Community.fromMap(event.data() as Map<String, dynamic>),
        );
  }

  //EDIT COMMUNITY VISUAL
  FutureVoid editCommunityProfileOrBannerImage(Community community) async {
    try {
      final Map<String, dynamic> communityAfterCast = {
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
  FutureVoid joinCommunity(
    String uid,
    String communityName,
    CommunityMembership membership,
  ) async {
    try {
      right(_communities.doc(communityName).update({
        'members': FieldValue.arrayUnion([uid]),
      }));
      final membershipId = uid + communityName;
      right(_membership.doc(membershipId).set(membership.toMap()));
      right(_communities.doc(communityName).update({
        'membersCount': FieldValue.increment(1),
      }));
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //LET USER JOIN COMMUNITY
  FutureVoid leaveCommunity(String uid, String communityName) async {
    try {
      right(_communities.doc(communityName).update({
        'members': FieldValue.arrayRemove([uid]),
      }));
      final membershipId = uid + communityName;
      right(_membership.doc(membershipId).delete());
      right(_communities.doc(communityName).update({
        'membersCount': FieldValue.increment(-1),
      }));
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  bool isMember(String uid, String communityName) {
    _loadMemberships();
    return _membershipsList.any((membership) =>
        membership['communityName'] == communityName &&
        membership['uid'] == uid);
  }

  Future<bool> isMod(String uid, String communityName) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('community_membership')
        .get();
    final moderatorsList = querySnapshot.docs.map((doc) => doc.data()).toList();
    return moderatorsList.any((membership) =>
        membership['communityName'] == communityName &&
        membership['uid'] == uid);
  }

  //GET THE COMMUNITIES DATA
  CollectionReference get _communities =>
      _firestore.collection(FirebaseConstants.communitiesCollection);
  CollectionReference get _membership =>
      _firestore.collection(FirebaseConstants.membershipCollection);
  CollectionReference get _moderators =>
      _firestore.collection(FirebaseConstants.moderatorsCollection);

  Future<void> _loadMemberships() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('community_moderators')
        .get();
    _membershipsList = querySnapshot.docs.map((doc) => doc.data()).toList();
  }
}
