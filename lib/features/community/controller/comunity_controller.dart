import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/repository/community_repository.dart';
import 'package:hash_balance/models/community_membership_model.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/conbined_models/current_user_role_model.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';

final currentUserRoleProvider = StreamProvider.family((ref, String communityId) {
  final uid = ref.read(userProvider)!.uid;
  return ref.watch(communityControllerProvider.notifier).getCurrentUserRole(communityId, uid);
});

final communityPostsProvider = StreamProvider.family((ref, String communityId) {

  return ref
      .watch(communityControllerProvider.notifier)
      .fetchCommunityPosts(communityId);
});

final fetchCommunitiesProvider = StreamProvider(
    (ref) => ref.read(communityControllerProvider.notifier).fetchCommunities());

final fetchCommunityByIdProvider =
    FutureProviderFamily((ref, String communityId) {
  return ref
      .watch(communityControllerProvider.notifier)
      .fetchCommunityById(communityId);
});

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

final getTopCommunityListProvider = StreamProvider((ref) {
  return ref
      .watch(communityControllerProvider.notifier)
      .getTopCommunitiesList();
});

final myCommunitiesProvider = StreamProvider((ref) {
  final communityController = ref.watch(communityControllerProvider.notifier);
  return communityController.getMyCommunities();
});

final userCommunitiesProvider = StreamProvider((ref) {
  final communityController = ref.watch(communityControllerProvider.notifier);
  return communityController.getUserCommunities();
});

final communityByIdProvider = StreamProvider.family((ref, String communityId) {
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
  Future<Either<Failures, String>> createCommunity(
    BuildContext context,
    String name,
    String type,
    String description,
    bool containsExposureContents,
  ) async {
    state = true;
    try {
      final currentUser = _ref.read(userProvider);
      final community = Community(
        id: await generateRandomId(),
        name: name,
        profileImage: Constants
            .avatarDefault[Random().nextInt(Constants.avatarDefault.length)],
        bannerImage: Constants.bannerDefault,
        type: type,
        description: description,
        containsExposureContents: containsExposureContents,
        createdAt: Timestamp.now(),
      );
      final result = await _communityRepository.createCommunity(community);
      await joinCommunityAsModerator(currentUser!.uid, community.id);
      return result;
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    } finally {
      state = false;
    }
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
  Future<Either<Failures, String>> joinCommunity(
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
        status: Constants.memberActiveStatus,
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
  Future<Either<Failures, String>> joinCommunityAsModerator(
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
        status: Constants.memberActiveStatus,
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
  Future<Either<Failures, String>> leaveCommunity(
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

  Stream<Community> getCommunityById(String communityId) {
    return _communityRepository.getCommunityById(communityId);
  }

  Future<Community> fetchCommunityById(String communityId) async {
    return await _communityRepository.fetchCommunityById(communityId);
  }

  Future<List<PostDataModel>> getCommunityPosts(String communityId) async {
    final list = await _communityRepository.getCommunityPosts(communityId);
    return list;
  }

  Stream<List<PostDataModel>> fetchCommunityPosts(String communityId) {
    return _communityRepository.fetchCommunityPosts(communityId);
  }

  Stream<List<Community>> fetchCommunities() {
    return _communityRepository.fetchCommunities();
  }

  Stream<CurrentUserRoleModel?> getCurrentUserRole(
    String communityId,
    String uid,
  ) {
    return _communityRepository.getCurrentUserRole(communityId, uid);
  }
}
