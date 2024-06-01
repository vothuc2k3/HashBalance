import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:routemaster/routemaster.dart';

import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/storage_repository_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/repository/community_repository.dart';
import 'package:hash_balance/models/community.dart';
import 'package:hash_balance/models/community_membership.dart';
import 'package:hash_balance/models/community_moderators.dart';

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
    try {
      final uid = _ref.read(userProvider)!.uid;
      Community community = Community(
        name: name,
        profileImage: Constants.avatarDefault,
        bannerImage: Constants.bannerDefault,
        type: type,
        containsExposureContents: containsExposureContents,
        membersCount: 1,
        createdAt: Timestamp.now(),
      );
      final membership = CommunityMembership(
        uid: uid,
        communityName: name,
      );
      final moderator = CommunityModerators(
        uid: uid,
        communityName: name,
      );
      final result = await _communityRepository.createCommunity(
        community,
        membership,
        moderator,
        uid,
      );

      result.fold((error) {
        showSnackBar(context, error.message);
      }, (right) {
        showSnackBar(context, 'Your Community Created Successfully. Have Fun!');
        Routemaster.of(context).pop();
      });
    } catch (e) {
      showSnackBar(context, 'An error occurred: ${e.toString()}');
    } finally {
      state = false;
    }
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
  FutureString editCommunityProfileOrBannerImage({
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
      CommunityMembership membership = CommunityMembership(
        uid: uid,
        communityName: communityName,
      );
      final result = await _communityRepository.joinCommunity(
        uid,
        communityName,
        membership,
      );
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

  //CHECK IF USER IS IN THE COMMUNITY
  bool isMember(String communityName) {
    final uid = _ref.watch(userProvider)!.uid;
    return _communityRepository.isMember(uid, communityName);
  }

  //CHECK IF USER IS THE MODERATOR
  Future<bool> isMod(String communityName) async {
    final uid = _ref.watch(userProvider)!.uid;
    return await _communityRepository.isMod(uid, communityName);
  }
}
