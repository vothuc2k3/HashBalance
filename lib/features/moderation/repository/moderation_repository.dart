import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/providers/storage_repository_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final moderationRepositoryProvider = Provider((ref) {
  return ModerationRepository(
      firestore: ref.watch(firebaseFirestoreProvider),
      storageRepository: ref.watch(storageRepositoryProvider));
});

class ModerationRepository {
  final FirebaseFirestore _firestore;
  final StorageRepository _storageRepository;

  ModerationRepository({
    required FirebaseFirestore firestore,
    required StorageRepository storageRepository,
  })  : _firestore = firestore,
        _storageRepository = storageRepository;

  CollectionReference get _communityMembership =>
      _firestore.collection(FirebaseConstants.communityMembershipCollection);
  CollectionReference get _communities =>
      _firestore.collection(FirebaseConstants.communitiesCollection);
  CollectionReference get _posts =>
      _firestore.collection(FirebaseConstants.postsCollection);
  CollectionReference get _friendships =>
      _firestore.collection(FirebaseConstants.friendshipCollection);
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);

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
    required Post post,
  }) async {
    try {
      await _posts.doc(post.id).update({
        'isPinned': true,
      });
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //PIN POST
  FutureVoid unPinPost({
    required Post post,
  }) async {
    try {
      await _posts.doc(post.id).update({
        'isPinned': false,
      });
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //APPROVE [OR] REJECT POST
  FutureVoid handlePostApproval(Post post, String decision) async {
    try {
      await _posts.doc(post.id).update({'status': decision});
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //FETCH CANDIDATES FOR MODERATION
  Future<List<UserModel>> fetchModeratorCandidates(
      String currentModeratorUid, String communityId) async {
    try {
      // Fetch friends of the current moderator, considering both uid1 and uid2
      final friendSnapshot1 = await _friendships
          .where('uid1', isEqualTo: currentModeratorUid)
          .get();

      final friendSnapshot2 = await _friendships
          .where('uid2', isEqualTo: currentModeratorUid)
          .get();

      // Combine both queries (uid1 or uid2)
      final friendsUids = friendSnapshot1.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['uid2'] as String)
          .toList();

      friendsUids.addAll(friendSnapshot2.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['uid1'] as String)
          .toList());

      if (friendsUids.isEmpty) {
        return [];
      }

      // Fetch current moderators in the community from membershipCollection
      final moderatorSnapshot = await _communityMembership
          .where('communityId', isEqualTo: communityId)
          .where('role',
              isEqualTo:
                  'moderator') // Assuming role field is used to identify moderators
          .get();

      final currentModerators =
          moderatorSnapshot.docs.map((doc) => doc['uid'] as String).toList();

      // Fetch user data for all friends
      final friendDataSnapshot =
          await _users.where(FieldPath.documentId, whereIn: friendsUids).get();

      final friends = friendDataSnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter out friends who are already moderators
      final moderatorCandidates = friends.where((friend) {
        return !currentModerators.contains(friend.uid);
      }).toList();

      return moderatorCandidates;
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  //DELETE THE POST
  FutureVoid deletePost(Post post, String uid) async {
    final batch = _firestore.batch();
    try {
      final postVotes = await _posts
          .doc(post.id)
          .collection(FirebaseConstants.postVoteCollection)
          .get();
      for (final postVote in postVotes.docs) {
        await postVote.reference.delete();
      }
      await _posts.doc(post.id).delete();

      await _storageRepository.deleteFile(
        path: 'posts/images/${post.id}',
      );
      await _storageRepository.deleteFile(
        path: 'posts/videos/${post.id}',
      );
      await batch.commit();
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, void>> uploadProfileImage(
    Community community,
    File profileImage,
  ) async {
    try {
      final result = await _storageRepository.storeFile(
        path: 'communities/profile',
        id: community.id,
        file: profileImage,
      );
      result.fold((l) => left(Failures(l.message)), (r) async {
        final profileImageUrl = await FirebaseStorage.instance
            .ref('communities/profile/${community.id}')
            .getDownloadURL();
        await _communities.doc(community.id).update({
          'profileImage': profileImageUrl,
        });
      });
      return right(null);
    } on FirebaseException catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw e.message ?? 'Unknown FirebaseException error';
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw e.toString();
    }
  }

  Future<Either<Failures, void>> uploadBannerImage(
    Community community,
    File bannerImage,
  ) async {
    try {
      final result = await _storageRepository.storeFile(
        path: 'communities/banner',
        id: community.id,
        file: bannerImage,
      );
      return result.fold((l) => left(Failures(l.message)), (r) async {
        final bannerImageUrl = await FirebaseStorage.instance
            .ref('communities/banner/${community.id}')
            .getDownloadURL();
        await _communities.doc(community.id).update({
          'bannerImage': bannerImageUrl,
        });
        return right(null);
      });
    } on FirebaseException catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw e.message ?? 'Unknown FirebaseException error';
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw e.toString();
    }
  }

  Stream<List<UserModel>> fetchInitialCommunityMembers(String communityId) {
    return _communityMembership
        .where('communityId', isEqualTo: communityId)
        .orderBy('joinedAt', descending: true)
        .limit(10)
        .snapshots() 
        .asyncMap((snapshot) async {
      List<String> memberUids = snapshot.docs.map((doc) {
        return doc['uid'] as String;
      }).toList();

      List<UserModel> members = [];
      for (String uid in memberUids) {
        final userSnapshot = await _users
            .doc(uid)
            .get();

        if (userSnapshot.exists) {
          UserModel user =
              UserModel.fromMap(userSnapshot.data() as Map<String, dynamic>);
          members.add(user);
        }
      }
      return members;
    });
  }
}
