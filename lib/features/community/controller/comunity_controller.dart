import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/repository/community_repository.dart';
import 'package:hash_balance/models/community_membership_model.dart';
import 'package:hash_balance/models/community_model.dart';

final getCommunityMemberCountProvider =
    StreamProvider.family.autoDispose((ref, String communityId) {
  return ref
      .read(communityControllerProvider.notifier)
      .getCommunityMemberCount(communityId);
});

final getMemberStatusProvider =
    StreamProvider.family.autoDispose((ref, String communityId) {
  return ref
      .read(communityControllerProvider.notifier)
      .getMemberStatus(communityId);
});

final getTopCommunityListProvider = StreamProvider.autoDispose((ref) {
  return ref
      .watch(communityControllerProvider.notifier)
      .getTopCommunitiesList();
});

final myCommunitiesProvider = StreamProvider.autoDispose((ref) {
  final communityController = ref.watch(communityControllerProvider.notifier);
  return communityController.getMyCommunities();
});

final userCommunitiesProvider = StreamProvider.autoDispose((ref) {
  final communityController = ref.watch(communityControllerProvider.notifier);
  return communityController.getUserCommunities();
});

final getCommunityByIdProvider =
    StreamProvider.family((ref, String communityId) {
  return ref
      .watch(communityControllerProvider.notifier)
      .getCommunityById(communityId);
});

final communityControllerProvider =
    StateNotifierProvider<CommunityController, bool>(
  (ref) {
    final communityRepository = ref.watch(communityRepositoryProvider);
    return CommunityController(
      communityRepository: communityRepository,
      ref: ref,
    );
  },
);

class CommunityController extends StateNotifier<bool> {
  final CommunityRepository _communityRepository;
  final Ref _ref;

  CommunityController({
    required CommunityRepository communityRepository,
    required Ref ref,
  })  : _communityRepository = communityRepository,
        _ref = ref,
        super(false);

  //CREATE A WHOLE NEW COMMUNITY
  FutureString createCommunity(
    BuildContext context,
    String name,
    String type,
    bool containsExposureContents,
  ) async {
    final currentUser = _ref.watch(userProvider);

    final Community community = Community(
      id: await generateRandomId(),
      name: name,
      profileImage: Constants
          .avatarDefault[Random().nextInt(Constants.avatarDefault.length)],
          pinPostId: '',
      bannerImage: Constants.bannerDefault,
      type: type,
      containsExposureContents: containsExposureContents,
      createdAt: Timestamp.now(),
    );

    await joinCommunityAsModerator(currentUser!.uid, community.id);

    final result = await _communityRepository.createCommunity(community);

    return result;
  }

  //GET THE COMMUNITIES BY CURRENT USER
  Stream<List<Community>> getUserCommunities() {
    final uid = _ref.read(userProvider)!.uid;
    return _communityRepository.getUserCommunities(uid);
  }

  Stream<List<Community>> getMyCommunities() {
    final uid = _ref.read(userProvider)!.uid;
    return _communityRepository.getMyCommunities(uid);
  }

  //LET USER JOIN COMMUNITY
  FutureString joinCommunity(
    String uid,
    String communityId,
  ) async {
    state = true;
    try {
      final newMembership = CommunityMembership(
        id: getMembershipId(uid, communityId),
        communityId: communityId,
        joinedAt: Timestamp.now(),
        uid: uid,
        role: Constants.memberRole,
      );

      final result = await _communityRepository.joinCommunity(newMembership);

      return result.fold(
        (l) => left(Failures(l.message)),
        (r) => right('Successfully Joined The Community!'),
      );
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    } finally {
      state = false;
    }
  }

  //JOIN AS MOD
  FutureString joinCommunityAsModerator(
    String uid,
    String communityId,
  ) async {
    try {
      final newMembership = CommunityMembership(
        id: getMembershipId(uid, communityId),
        communityId: communityId,
        joinedAt: Timestamp.now(),
        uid: uid,
        role: Constants.moderatorRole,
      );

      final result = await _communityRepository.joinCommunity(newMembership);

      return result.fold(
        (l) => left(Failures(l.message)),
        (r) => right('Successfully Joined The Community!'),
      );
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //LET USER LEAVE COMMUNITY
  FutureString leaveCommunity(
    String uid,
    String communityId,
  ) async {
    state = true;
    try {
      final result = await _communityRepository
          .leaveCommunity(getMembershipId(uid, communityId));

      return result.fold(
        (l) => left(Failures(l.message)),
        (r) => right('Successfully Left The Community!'),
      );
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    } finally {
      state = false;
    }
  }

  //CHECK IF THE USER IS MEMBER OF COMMUNITY
  Stream<bool> getMemberStatus(String communityId) {
    try {
      final currentUser = _ref.watch(userProvider);
      return _communityRepository
          .getMemberStatus(getMembershipId(currentUser!.uid, communityId));
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  Stream<List<Community>?> getTopCommunitiesList() {
    return _communityRepository.getTopCommunitiesList();
  }

  Stream<int> getCommunityMemberCount(String communityId) {
    return _communityRepository.getCommunityMemberCount(communityId);
  }

  Stream<Community?> getCommunityById(String communityId) {
    return _communityRepository.getCommunityById(communityId);
  }
}
