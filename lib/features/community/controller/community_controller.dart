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
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

final initialCommunityMembersProvider =
    FutureProviderFamily((ref, String communityId) {
  return ref
      .read(communityControllerProvider.notifier)
      .getInitialCommunityMembers(communityId);
});

final currentUserRoleProvider =
    StreamProvider.family.autoDispose((ref, Tuple2<String, String> data) {
  return ref
      .watch(communityControllerProvider.notifier)
      .getCurrentUserRole(data);
});

final communityPostsProvider = StreamProvider.family((ref, String communityId) {
  return ref
      .watch(communityControllerProvider.notifier)
      .fetchCommunityPosts(communityId);
});

final fetchCommunitiesProvider = FutureProvider((ref) async {
  return await ref
      .read(communityControllerProvider.notifier)
      .fetchCommunities();
});

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

final getTopCommunityListProvider = FutureProvider((ref) {
  return ref
      .watch(communityControllerProvider.notifier)
      .getTopCommunitiesList();
});

final myCommunitiesProvider = StreamProvider((ref) {
  final communityController = ref.watch(communityControllerProvider.notifier);
  return communityController.getMyCommunities();
});

final userCommunitiesProvider = StreamProvider((ref) =>
    ref.watch(communityControllerProvider.notifier).getUserCommunities());

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
  final Uuid _uuid = const Uuid();

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
        id: _uuid.v1(),
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
      await joinCommunityAsCreator(currentUser!.uid, community.id);
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
        id: getMembershipId(uid: uid, communityId: communityId),
        communityId: communityId,
        joinedAt: Timestamp.now(),
        uid: uid,
        role: Constants.memberRole,
        status: Constants.memberActiveStatus,
        isCreator: false,
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
        id: getMembershipId(uid: uid, communityId: communityId),
        communityId: communityId,
        joinedAt: Timestamp.now(),
        uid: uid,
        role: Constants.moderatorRole,
        status: Constants.memberActiveStatus,
        isCreator: false,
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

  //JOIN AS MOD
  Future<Either<Failures, String>> joinCommunityAsCreator(
    String uid,
    String communityId,
  ) async {
    try {
      final newMembership = CommunityMembership(
        id: getMembershipId(uid: uid, communityId: communityId),
        communityId: communityId,
        joinedAt: Timestamp.now(),
        uid: uid,
        role: Constants.moderatorRole,
        status: Constants.memberActiveStatus,
        isCreator: true,
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
          .leaveCommunity(getMembershipId(uid: uid, communityId: communityId));

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
      return _communityRepository.getMemberStatus(
          getMembershipId(uid: currentUser!.uid, communityId: communityId));
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  Future<List<Tuple2<Community, int>>> getTopCommunitiesList() async {
    return await _communityRepository.getTopCommunitiesList();
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

  Future<List<Community>> fetchCommunities() async {
    return await _communityRepository.fetchCommunities();
  }

  Stream<CurrentUserRoleModel?> getCurrentUserRole(
    Tuple2<String, String> data,
  ) {
    return _communityRepository.getCurrentUserRole(data.item1, data.item2);
  }

  Future<Either<Failures, bool>> fetchSuspendStatus({
    required String communityId,
    required String uid,
  }) async {
    return await _communityRepository.fetchSuspendStatus(
        communityId: communityId, uid: uid);
  }

  Future<String> getMemberRole(String uid, String communityId) async {
    return await _communityRepository
        .getMemberRole(getMembershipId(uid: uid, communityId: communityId));
  }

  Future<List<CurrentUserRoleModel?>> getInitialCommunityMembers(
      String communityId) async {
    return await _communityRepository.getInitialCommunityMembers(communityId);
  }

  Future<List<CurrentUserRoleModel?>> getMoreCommunityMembers(
      String communityId, Timestamp? lastJoinedAt) async {
    return await _communityRepository.getMoreCommunityMembers(
      communityId,
      lastJoinedAt,
    );
  }
}
