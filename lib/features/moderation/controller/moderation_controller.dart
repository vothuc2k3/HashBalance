import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/storage_repository_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/moderation/repository/moderation_repository.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/post_model.dart';

final getMembershipStatusProvider =
    StreamProvider.family.autoDispose((ref, String communityId) {
  return ref
      .read(moderationControllerProvider.notifier)
      .getMembershipStatus(communityId);
});

final moderationControllerProvider =
    StateNotifierProvider<ModerationController, bool>((ref) {
  return ModerationController(
    moderationRepository: ref.read(moderationRepositoryProvider),
    storageRepository: ref.read(storageRepositoryProvider),
    ref: ref,
  );
});

class ModerationController extends StateNotifier<bool> {
  final ModerationRepository _moderationRepository;
  final StorageRepository _storageRepository;
  final Ref _ref;

  ModerationController({
    required ModerationRepository moderationRepository,
    required StorageRepository storageRepository,
    required Ref ref,
  })  : _moderationRepository = moderationRepository,
        _storageRepository = storageRepository,
        _ref = ref,
        super(false);

  Stream<String> getMembershipStatus(String communityId) {
    final currentUser = _ref.watch(userProvider);
    return _moderationRepository
        .getMembershipStatus(getMembershipId(currentUser!.uid, communityId));
  }

  //EDIT COMMUNITY VISUAL
  FutureString editCommunityProfileOrBannerImage({
    required Community community,
    required File? profileImage,
    required File? bannerImage,
  }) async {
    state = true;
    try {
      Community updatedCommunity = community;

      if (profileImage != null) {
        final result = await _storageRepository.storeFile(
            path: 'communities/profile', id: community.id, file: profileImage);
        await result.fold(
          (error) => throw FirebaseException(
            plugin: 'Firebase Exception',
            message: error.message,
          ),
          (right) async {
            String profileImageUrl = await FirebaseStorage.instance
                .ref('communities/profile/${community.id}')
                .getDownloadURL();
            updatedCommunity =
                updatedCommunity.copyWith(profileImage: profileImageUrl);
          },
        );
      }

      if (bannerImage != null) {
        final result = await _storageRepository.storeFile(
          path: 'communities/banner',
          id: community.id,
          file: bannerImage,
        );
        await result.fold(
          (error) => throw FirebaseException(
            plugin: 'Firebase Exception',
            message: error.message,
          ),
          (right) async {
            String bannerImageUrl = await FirebaseStorage.instance
                .ref('communities/banner/${community.id}')
                .getDownloadURL();
            updatedCommunity =
                updatedCommunity.copyWith(bannerImage: bannerImageUrl);
          },
        );
      }

      final result = await _moderationRepository
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

  FutureString fetchMembershipStatus(String membershipId) async {
    return _moderationRepository.fetchMembershipStatus(membershipId);
  }

  //PIN POST
  FutureVoid pinPost({required Post post}) async {
    try {
      final result = await _moderationRepository.pinPost(
        post: post,
      );
      return result;
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  FutureVoid unPinPost(Post post) async {
    try {
      return await _moderationRepository.unPinPost(post: post);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //APPROVE [OR] REJECT POST
  FutureVoid handlePostApproval(Post post, String decision) async {
    try {
      return await _moderationRepository.handlePostApproval(post, decision);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }
}
