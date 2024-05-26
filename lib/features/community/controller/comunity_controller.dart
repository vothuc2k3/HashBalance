import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:routemaster/routemaster.dart';

import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/core/providers/storage_repository_providers.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/repository/community_repository.dart';
import 'package:hash_balance/models/community_model.dart';

final userCommunitiesProvider = StreamProvider((ref) {
  final communityController = ref.watch(communityControllerProvider.notifier);
  return communityController.getUserCommunities();
});

final getCommunitiesByNameProvider = StreamProvider.family((ref, String name) {
  return ref
      .watch(communityControllerProvider.notifier)
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

    final result = await _communityRepository.createCommunity(community);

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

  //GET THE COMMUNITIES BY CURRENT USER
  Stream<List<Community>> getUserCommunities() {
    final uid = _ref.read(userProvider)!.uid;
    return _communityRepository.getUserCommunities(uid);
  }

  //GET THE COMMUNITY BY NAME
  Stream<Community> getCommunityByName(String name) {
    return _communityRepository.getCommunityByName(name);
  }

  //EDIT COMMUNITY VISUAL
  Future<Either<Failures, String>> editCommunityProfileOrBannerImage({
    required BuildContext context,
    required Community community,
    required File? profileImage,
    required File? bannerImage,
  }) async {
    state = true;
    try {
      Community updatedCommunity = community;

      if (profileImage != null) {
        final result = await _storageRepository.storeFile(
          path: 'communities/profile',
          id: community.name,
          file: profileImage,
        );
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
    } finally {
      state = false;
    }
  }

  //LET USER JOIN COMMUNITY
  FutureString joinCommunity(
    String uid,
    String communityName,
  ) async {
    state = true;
    try {
      final result =
          await _communityRepository.joinCommunity(uid, communityName);
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

  //LET USER LEAVE COMMUNITY
  FutureString leaveCommunity(
    String uid,
    String communityName,
  ) async {
    state = true;
    try {
      final result =
          await _communityRepository.leaveCommunity(uid, communityName);
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
}
