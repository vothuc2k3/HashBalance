import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/storage_repository_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/moderation/repository/moderation_repository.dart';
import 'package:hash_balance/features/notification/controller/notification_controller.dart';
import 'package:hash_balance/features/push_notification/controller/push_notification_controller.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/notification_model.dart';
import 'package:hash_balance/models/post_model.dart';

final getMembershipStatusProvider =
    StreamProvider.family.autoDispose((ref, String communityId) {
  return ref
      .read(moderationControllerProvider.notifier)
      .getMembershipStatus(communityId);
});

final moderationControllerProvider =
    StateNotifierProvider<ModerationController, bool>(
  (ref) {
    return ModerationController(
      moderationRepository: ref.read(moderationRepositoryProvider),
      storageRepository: ref.read(storageRepositoryProvider),
      notificationController: ref.read(notificationControllerProvider.notifier),
      pushNotificationController:
          ref.read(pushNotificationControllerProvider.notifier),
      userController: ref.read(userControllerProvider.notifier),
      ref: ref,
    );
  },
);

class ModerationController extends StateNotifier<bool> {
  final ModerationRepository _moderationRepository;
  final StorageRepository _storageRepository;
  final NotificationController _notificationController;
  final PushNotificationController _pushNotificationController;
  final UserController _userController;
  final Ref _ref;

  ModerationController({
    required ModerationRepository moderationRepository,
    required StorageRepository storageRepository,
    required NotificationController notificationController,
    required PushNotificationController pushNotificationController,
    required UserController userController,
    required Ref ref,
  })  : _moderationRepository = moderationRepository,
        _storageRepository = storageRepository,
        _notificationController = notificationController,
        _pushNotificationController = pushNotificationController,
        _userController = userController,
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

  FutureVoid inviteAsModerator(String uid, Community community) async {
    try {
      final currentUser = _ref.watch(userProvider)!;
      final notif = NotificationModel(
        id: await generateRandomId(),
        title: Constants.moderatorInvitationTitle,
        message: Constants.getModeratorInvitationContent(
          currentUser.name,
          community.name,
        ),
        type: Constants.moderatorInvitationType,
        targetUid: uid,
        senderUid: currentUser.uid,
        createdAt: Timestamp.now(),
        isRead: false,
      );
      await _notificationController.addNotification(uid, notif);

      //SEND PUSH NOTIFICATION TO THE TARGET
      final targetUserDeviceIds =
          await _userController.getUserDeviceTokens(uid);
      await _pushNotificationController.sendPushNotification(
        targetUserDeviceIds,
        notif.message,
        notif.title,
        {
          'type': Constants.moderatorInvitationType,
          'uid': currentUser.uid,
          'communityId': community.id,
        },
      );
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }
}
