import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/storage_repository_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/repository/community_repository.dart';
import 'package:hash_balance/models/community_membership_model.dart';
import 'package:hash_balance/models/community_model.dart';

final getModeratorStatus =
    StreamProvider.family.autoDispose((ref, String communityName) {
  return ref
      .read(communityControllerProvider.notifier)
      .getModeratorStatus(communityName);
});

final getCommunityMemberCountProvider =
    StreamProvider.family.autoDispose((ref, String communityName) {
  return ref
      .read(communityControllerProvider.notifier)
      .getCommunityMemberCount(communityName);
});

final getMemberStatusProvider =
    StreamProvider.family.autoDispose((ref, String communityName) {
  return ref
      .read(communityControllerProvider.notifier)
      .getMemberStatus(communityName);
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

final getCommunityByNameProvider =
    StreamProvider.family.autoDispose((ref, String name) {
  return ref
      .read(communityControllerProvider.notifier)
      .getCommunityByName(name);
});

final communityControllerProvider =
    StateNotifierProvider<CommunityController, bool>(
  (ref) {
    final storageRepository = ref.watch(storageRepositoryProvider);
    final communityRepository = ref.watch(communityRepositoryProvider);
    return CommunityController(
      communityRepository: communityRepository,
      storageRepository: storageRepository,
      ref: ref,
    );
  },
);

class CommunityController extends StateNotifier<bool> {
  final CommunityRepository _communityRepository;
  final Ref _ref;
  final StorageRepository _storageRepository;

  CommunityController({
    required CommunityRepository communityRepository,
    required Ref ref,
    required StorageRepository storageRepository,
  })  : _communityRepository = communityRepository,
        _ref = ref,
        _storageRepository = storageRepository,
        super(false);

  //CREATE A WHOLE NEW COMMUNITY
  void createCommunity(
    BuildContext context,
    String name,
    String type,
    bool containsExposureContents,
  ) async {
    final currentUser = _ref.watch(userProvider);

    final Community community = Community(
      id: generateRandomId(),
      name: name,
      profileImage: Constants
          .avatarDefault[Random().nextInt(Constants.avatarDefault.length)],
      bannerImage: Constants.bannerDefault,
      type: type,
      containsExposureContents: containsExposureContents,
      createdAt: Timestamp.now(),
    );
    final communityController = CommunityController(
      communityRepository: _communityRepository,
      ref: _ref,
      storageRepository: _storageRepository,
    );

    await communityController.joinCommunityAsModerator(
        currentUser!.uid, community.name);

    final result = await _communityRepository.createCommunity(community);

    result.fold(
      (error) {
        return showSnackBar(context, error.message);
      },
      (right) {
        showSnackBar(context, 'Your Community Created Successfully. Have Fun!');
        Navigator.pop(context);
      },
    );
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

  //GET THE COMMUNITY BY NAME
  Stream<Community> getCommunityByName(String name) {
    return _communityRepository.getCommunityByName(name);
  }

  //EDIT COMMUNITY VISUAL
  FutureString editCommunityProfileOrBannerImage({
    required BuildContext context,
    required Community community,
    required File? profileImage,
    required File? bannerImage,
  }) async {
    try {
      Community updatedCommunity = community;

      if (profileImage != null) {
        final result = await _storageRepository.storeFile(
            path: 'communities/profile',
            id: community.name,
            file: profileImage);
        await result.fold(
          (error) => throw FirebaseException(
            plugin: 'Firebase Exception',
            message: error.message,
          ),
          (right) async {
            String profileImageUrl = await FirebaseStorage.instance
                .ref('communities/profile/${community.name}')
                .getDownloadURL();
            updatedCommunity =
                updatedCommunity.copyWith(profileImage: profileImageUrl);
          },
        );
      }

      if (bannerImage != null) {
        final result = await _storageRepository.storeFile(
          path: 'communities/banner',
          id: community.name,
          file: bannerImage,
        );
        await result.fold(
          (error) => throw FirebaseException(
            plugin: 'Firebase Exception',
            message: error.message,
          ),
          (right) async {
            String bannerImageUrl = await FirebaseStorage.instance
                .ref('communities/banner/${community.name}')
                .getDownloadURL();
            updatedCommunity =
                updatedCommunity.copyWith(bannerImage: bannerImageUrl);
          },
        );
      }

      final result = await _communityRepository
          .editCommunityProfileOrBannerImage(updatedCommunity);

      return result.fold(
        (l) => left(Failures(l.message)),
        (r) => right('Community profile or banner image updated successfully'),
      );
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //LET USER JOIN COMMUNITY
  FutureString joinCommunity(
    String uid,
    String communityName,
  ) async {
    try {
      final newMembership = CommunityMembership(
        id: getMembershipId(uid, communityName),
        communityName: communityName,
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
    }
  }

  //JOIN AS MOD
  FutureString joinCommunityAsModerator(
    String uid,
    String communityName,
  ) async {
    try {
      final newMembership = CommunityMembership(
        id: getMembershipId(uid, communityName),
        communityName: communityName,
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
    String communityName,
  ) async {
    try {
      final result = await _communityRepository
          .leaveCommunity(getMembershipId(uid, communityName));

      return result.fold(
        (l) => left(Failures(l.message)),
        (r) => right('Successfully Left The Community!'),
      );
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //CHECK IF THE USER IS MEMBER OF COMMUNITY
  Stream<bool> getMemberStatus(String communityName) {
    try {
      final currentUser = _ref.watch(userProvider);
      return _communityRepository
          .getMemberStatus(getMembershipId(currentUser!.uid, communityName));
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  Stream<List<Community>?> getTopCommunitiesList() {
    return _communityRepository.getTopCommunitiesList();
  }

  Stream<int> getCommunityMemberCount(String communityName) {
    return _communityRepository.getCommunityMemberCount(communityName);
  }

  Stream<bool> getModeratorStatus(String communityName) {
    final currentUser = _ref.watch(userProvider);
    return _communityRepository
        .getModeratorStatus(getMembershipId(currentUser!.uid, communityName));
  }
}
