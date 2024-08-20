import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/post_model.dart';

final moderationRepositoryProvider = Provider((ref) {
  return ModerationRepository(firestore: ref.watch(firebaseFirestoreProvider));
});

class ModerationRepository {
  final FirebaseFirestore _firestore;

  ModerationRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  CollectionReference get _communityMembership =>
      _firestore.collection(FirebaseConstants.communityMembershipCollection);
  CollectionReference get _communities =>
      _firestore.collection(FirebaseConstants.communitiesCollection);

  //GET MODERATOR STATUS
  Stream<String> getMembershipStatus(String membershipId) {
    return _communityMembership.doc(membershipId).snapshots().map((event) {
      if (event.data() == null) {
        return '';
      }
      final data = event.data() as Map<String, dynamic>;
      final role = data['role'] as String;
      if (role == Constants.moderatorRole) {
        return 'moderator';
      }
      return 'member';
    });
  }

  //FETCH MEMBERSHIP STATUS
  FutureString fetchMembershipStatus(String membershipId) async {
    try {
      final membershipDoc = await _communityMembership.doc(membershipId).get();
      if (!membershipDoc.exists) {
        return right('');
      }
      final data = membershipDoc.data() as Map<String, dynamic>;
      final role = data['role'] as String;
      if (role == Constants.moderatorRole) {
        return right('moderator');
      }
      return right('member');
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
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

  //PIN POST
  FutureVoid pinPost({
    required Community community,
    required Post post,
  }) async {
    try {
      await _communities.doc(community.id).update({
        'pinPostId': post.id,
      });
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }
}
