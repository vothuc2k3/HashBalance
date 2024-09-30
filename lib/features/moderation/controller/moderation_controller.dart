import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/storage_repository_providers.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/comment/controller/comment_controller.dart';
import 'package:hash_balance/features/invitation/controller/invitation_controller.dart';
import 'package:hash_balance/features/moderation/repository/moderation_repository.dart';
import 'package:hash_balance/features/notification/controller/notification_controller.dart';
import 'package:hash_balance/features/push_notification/controller/push_notification_controller.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/conbined_models/current_user_role_model.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';
import 'package:hash_balance/models/conbined_models/suspended_user_combined_model.dart';
import 'package:hash_balance/models/notification_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/suspend_user_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:uuid/uuid.dart';

final fetchSuspendedUsersProvider =
    StreamProvider.family((ref, String communityId) {
  return ref
      .watch(moderationControllerProvider.notifier)
      .fetchSuspendedUsers(communityId);
});

final getArchivedPostsProvider =
    StreamProvider.family((ref, String communityId) {
  return ref
      .read(moderationControllerProvider.notifier)
      .getArchivedPosts(communityId);
});

final fetchInitialCommunityMembersProvider =
    StreamProvider.family((ref, String communityId) {
  return ref
      .read(moderationControllerProvider.notifier)
      .fetchInitialCommunityMembers(communityId);
});

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
      invitationController: ref.read(invitationControllerProvider),
      notificationController: ref.read(notificationControllerProvider.notifier),
      pushNotificationController:
          ref.read(pushNotificationControllerProvider.notifier),
      commentController: ref.read(commentControllerProvider.notifier),
      userController: ref.read(userControllerProvider.notifier),
      ref: ref,
    );
  },
);

class ModerationController extends StateNotifier<bool> {
  final ModerationRepository _moderationRepository;
  final StorageRepository _storageRepository;
  final InvitationController _invitationController;
  final NotificationController _notificationController;
  final PushNotificationController _pushNotificationController;
  final CommentController _commentController;
  final UserController _userController;
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  ModerationController({
    required ModerationRepository moderationRepository,
    required StorageRepository storageRepository,
    required InvitationController invitationController,
    required NotificationController notificationController,
    required PushNotificationController pushNotificationController,
    required CommentController commentController,
    required UserController userController,
    required Ref ref,
  })  : _moderationRepository = moderationRepository,
        _storageRepository = storageRepository,
        _invitationController = invitationController,
        _notificationController = notificationController,
        _pushNotificationController = pushNotificationController,
        _commentController = commentController,
        _userController = userController,
        _ref = ref,
        super(false);

  Stream<String> getMembershipStatus(String communityId) {
    final currentUser = _ref.watch(userProvider);
    return _moderationRepository
        .getMembershipStatus(getMembershipId(currentUser!.uid, communityId));
  }

  //EDIT COMMUNITY VISUAL
  Future<Either<Failures, String>> editCommunityProfileOrBannerImage({
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

  Future<Either<Failures, String>> fetchMembershipStatus(
      String membershipId) async {
    return _moderationRepository.fetchMembershipStatus(membershipId);
  }

  //PIN POST
  Future<Either<Failures, void>> pinPost({required Post post}) async {
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

  Future<Either<Failures, void>> unpinPost(Post post) async {
    try {
      return await _moderationRepository.unpinPost(post: post);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //APPROVE [OR] REJECT POST
  Future<Either<Failures, void>> handlePostApproval(
      Post post, String decision) async {
    try {
      return await _moderationRepository.handlePostApproval(post, decision);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //INVITE A FRIEND TO JOIN MODERATION
  Future<Either<Failures, void>> inviteAsModerator(
      String uid, Community community) async {
    try {
      final currentUser = _ref.watch(userProvider)!;

      //SEND INVITATION
      await _invitationController.addInvitation(
        uid,
        Constants.moderatorInvitationTitle,
        community.id,
      );

      //ADD NOTIFICATION TO THE INVITEE
      final notif = NotificationModel(
        id: _uuid.v1(),
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
        Constants.moderatorInvitationType,
      );
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<List<UserModel>> fetchModeratorCandidates(String communityId) async {
    try {
      final currentUser = _ref.read(userProvider)!;
      return await _moderationRepository.fetchModeratorCandidates(
          currentUser.uid, communityId);
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  Future<Either<Failures, void>> deletePost(Post post) async {
    try {
      final user = _ref.watch(userProvider)!;
      final result = await _moderationRepository.deletePost(post, user.uid);
      result.fold((l) => left(l), (r) async {
        if (post.image != '') {
          _storageRepository.deleteFile(
            path: 'posts/images/${post.id}',
          );
        }
        if (post.video != '') {
          _storageRepository.deleteFile(
            path: 'posts/videos/${post.id}',
          );
        }
        await _commentController.clearPostComments(post.id);
      });
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, void>> uploadProfileImage(
      Community community, File profileImage) async {
    try {
      final result = await _moderationRepository.uploadProfileImage(
        community,
        profileImage,
      );
      return result;
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, void>> uploadBannerImage(
      Community community, File bannerImage) async {
    try {
      final result = await _moderationRepository.uploadBannerImage(
        community,
        bannerImage,
      );
      return result;
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<List<CurrentUserRoleModel>> fetchInitialCommunityMembers(
      String communityId) {
    try {
      return _moderationRepository.fetchInitialCommunityMembers(communityId);
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  Future<Either<Failures, void>> archivePost({required String postId}) async {
    try {
      return await _moderationRepository.updatePostStatus(
        postId: postId,
        status: 'Archived',
      );
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, void>> unarchivePost({required String postId}) async {
    try {
      return await _moderationRepository.updatePostStatus(
        postId: postId,
        status: 'Approved',
      );
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, void>> changeCommunityType({
    required String communityId,
    required String type,
  }) async {
    state = true;
    try {
      return await _moderationRepository.changeCommunityType(
        communityId: communityId,
        type: type,
      );
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    } finally {
      state = false;
    }
  }

  Stream<List<PostDataModel>> getArchivedPosts(String communityId) {
    return _moderationRepository.getArchivedPosts(communityId);
  }

  Future<Either<Failures, void>> suspendUser({
    required String uid,
    required String communityId,
    required bool isPermanent,
    required String reason,
    required Timestamp expiresAt,
  }) async {
    final suspendUserModel = SuspendUserModel(
      id: _uuid.v1(),
      uid: uid,
      communityId: communityId,
      reason: reason,
      isPermanent: isPermanent,
      suspendedAt: Timestamp.now(),
      expiresAt: expiresAt,
    );
    return await _moderationRepository.suspendUser(
        suspendUserModel: suspendUserModel);
  }

  Stream<List<SuspendedUserCombinedModel>> fetchSuspendedUsers(String communityId) {
    return _moderationRepository.fetchSuspendedUsers(communityId);
  }
}
