import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/core/providers/storage_repository_providers.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/gaming_community/repository/gaming_community_repository.dart';
import 'package:hash_balance/models/gaming_community_model.dart';
import 'package:routemaster/routemaster.dart';

final userCommunitiesProvider = StreamProvider((ref) {
  final communityController =
      ref.watch(gamingCommunityControllerProvider.notifier);
  return communityController.getUserCommunities();
});

final getCommunitiesByNameProvider = StreamProvider.family((ref, String name) {
  return ref
      .watch(gamingCommunityControllerProvider.notifier)
      .getCommunitiesByName(name);
});

final gamingCommunityControllerProvider =
    StateNotifierProvider<GamingCommunityController, bool>(
  (ref) {
    final storageRepository = ref.watch(storageRepositoryProvider);
    final gamingCommunityRepository =
        ref.watch(gamingCommunityRepositoryProvider);
    return GamingCommunityController(
      gamingCommunityRepository: gamingCommunityRepository,
      storageRepository: storageRepository,
      ref: ref,
    );
  },
);

class GamingCommunityController extends StateNotifier<bool> {
  final GamingCommunityRepository _gamingCommunityRepository;
  final Ref _ref;
  final StorageRepository _storageRepository;

  GamingCommunityController({
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

    GamingCommunityModel community = GamingCommunityModel(
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

  Stream<List<GamingCommunityModel>> getUserCommunities() {
    final uid = _ref.read(userProvider)!.uid;
    return _gamingCommunityRepository.getUserCommunities(uid);
  }

  Stream<GamingCommunityModel> getCommunitiesByName(String name) {
    return _gamingCommunityRepository.getCommunitiesByName(name);
  }

  //submit the edit data of Community to Firebase
  void editCommunityProfileOrBannerImage(
      {required BuildContext context,
      required GamingCommunityModel community,
      required File? profileImage,
      required File? bannerImage}) async {
    if (profileImage != null) {
      final result = await _storageRepository.storeFile(
        path: 'communities/profile',
        id: community.id,
        file: profileImage,
      );
      result.fold((l) => showSnackBar(context, l.message),
          (r) => community.copyWith(profileImage: r));
    }

    if (bannerImage != null) {
      final result = await _storageRepository.storeFile(
        path: 'communities/banner',
        id: community.id,
        file: bannerImage,
      );
      result.fold((l) => showSnackBar(context, l.message),
          (r) => community.copyWith(bannerImage: r));
    }

    final result = await _gamingCommunityRepository
        .editCommunityProfileOrBannerImage(community);
    result.fold(
      (l) => showSnackBar(context, l.message),
      (r) => Routemaster.of(context).pop(),
    );
  }
}
