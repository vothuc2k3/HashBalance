import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';

import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/core/providers/storage_repository_providers.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/repository/community_repository.dart';
import 'package:hash_balance/models/community_model.dart';

final userCommunitiesProvider = StreamProvider((ref) {
  final communityController =
      ref.watch(gamingCommunityControllerProvider.notifier);
  return communityController.getUserCommunities();
});

final getCommunitiesByNameProvider = StreamProvider.family((ref, String name) {
  return ref
      .watch(gamingCommunityControllerProvider.notifier)
      .getCommunityByName(name);
});

final searchCommunityProvider = StreamProvider.family((ref, String query) {
  return ref
      .watch(gamingCommunityControllerProvider.notifier)
      .searchCommunity(query);
});

final gamingCommunityControllerProvider =
    StateNotifierProvider<CommunityController, bool>(
  (ref) {
    final storageRepository = ref.watch(storageRepositoryProvider);
    final gamingCommunityRepository =
        ref.watch(gamingCommunityRepositoryProvider);
    return CommunityController(
      gamingCommunityRepository: gamingCommunityRepository,
      storageRepository: storageRepository,
      ref: ref,
    );
  },
);

class CommunityController extends StateNotifier<bool> {
  final GamingCommunityRepository _gamingCommunityRepository;
  final Ref _ref;
  final StorageRepository _storageRepository;

  CommunityController({
    required GamingCommunityRepository gamingCommunityRepository,
    required Ref ref,
    required StorageRepository storageRepository,
  })  : _gamingCommunityRepository = gamingCommunityRepository,
        _ref = ref,
        _storageRepository = storageRepository,
        super(false);

  void createGamingCommunity(
    BuildContext context,
    String name,
    String type,
    bool containsExposureContents,
  ) async {
    state = true;

    final uid = _ref.read(userProvider)?.uid ?? '';

    Community community = Community(
      id: generateCommunityId(),
      name: name,
      profileImage: Constants.avatarDefault,
      bannerImage: Constants.bannerDefault,
      type: type,
      containsExposureContents: containsExposureContents,
      members: [uid],
      mods: [uid],
    );

    final result =
        await _gamingCommunityRepository.createGamingCommunity(community);

    state = false;

    result.fold(
      (error) {
        return showSnackBar(
          context,
          error.message,
        );
      },
      (right) {
        showSnackBar(
          context,
          'Your Community Created Successfully. Have Fun!',
        );
        Routemaster.of(context).pop();
      },
    );
  }

  Stream<List<Community>> getUserCommunities() {
    final uid = _ref.read(userProvider)!.uid;
    return _gamingCommunityRepository.getUserCommunities(uid);
  }

  Stream<Community> getCommunityByName(String name) {
    return _gamingCommunityRepository.getCommunityByName(name);
  }

  //submit the edit visual data of Community to Firebase
  void editCommunityProfileOrBannerImage({
    required BuildContext context,
    required Community community,
    required File? profileImage,
    required File? bannerImage,
  }) async {
    state = true;
    late Community updatedCommunity = community;

    if (profileImage != null) {
      final result = await _storageRepository.storeFile(
        path: 'communities/profile',
        id: community.name,
        file: profileImage,
      );
      String profileImageUrl = await FirebaseStorage.instance
          .ref('communities/profile/${community.name}')
          .getDownloadURL();
      result.fold(
        (error) => showSnackBar(context, error.message),
        (right) => updatedCommunity =
            community.copyWith(profileImage: profileImageUrl),
      );
    }

    if (bannerImage != null) {
      final result = await _storageRepository.storeFile(
        path: 'communities/banner',
        id: community.name,
        file: bannerImage,
      );
      String bannerImageUrl = await FirebaseStorage.instance
          .ref('communities/banner/${community.name}')
          .getDownloadURL();
      result.fold(
        (error) => showSnackBar(context, error.message),
        (right) =>
            updatedCommunity = community.copyWith(bannerImage: bannerImageUrl),
      );
    }

    final result = await _gamingCommunityRepository
        .editCommunityProfileOrBannerImage(updatedCommunity);
    state = false;

    result.fold(
      (l) => showSnackBar(context, l.message),
      (r) => Routemaster.of(context).pop(),
    );
  }

  //pass the query in the repo
  Stream<List<Community>> searchCommunity(String query) {
    return _gamingCommunityRepository.searchCommunity(query);
  }
}
