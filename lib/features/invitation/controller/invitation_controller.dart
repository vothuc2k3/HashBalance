import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/invitation/repository/invitation_repository.dart';
import 'package:hash_balance/features/notification/controller/notification_controller.dart';
import 'package:hash_balance/features/push_notification/controller/push_notification_controller.dart';
import 'package:hash_balance/features/user_devices/controller/user_device_controller.dart';
import 'package:hash_balance/models/invitation_model.dart';
import 'package:hash_balance/models/notification_model.dart';
import 'package:uuid/uuid.dart';

final invitationProvider = StreamProviderFamily((ref, String communityId) =>
    ref.watch(invitationControllerProvider).fetchInvitation(communityId));

final invitationControllerProvider = Provider((ref) {
  return InvitationController(
    ref: ref,
    invitationRepository: ref.read(invitationRepositoryProvider),
    pushNotificationController:
        ref.read(pushNotificationControllerProvider.notifier),
    userDeviceController: ref.read(userDeviceControllerProvider),
    notificationController: ref.read(notificationControllerProvider.notifier),
  );
});

class InvitationController {
  final Ref _ref;
  final InvitationRepository _invitationRepository;
  final PushNotificationController _pushNotificationController;
  final UserDeviceController _userDeviceController;
  final NotificationController _notificationController;
  final Uuid _uuid = const Uuid();
  InvitationController({
    required Ref ref,
    required InvitationRepository invitationRepository,
    required PushNotificationController pushNotificationController,
    required UserDeviceController userDeviceController,
    required NotificationController notificationController,
  })  : _ref = ref,
        _invitationRepository = invitationRepository,
        _pushNotificationController = pushNotificationController,
        _userDeviceController = userDeviceController,
        _notificationController = notificationController;

  Future<Either<Failures, void>> addMembershipInvitation(
    String receiverUid,
    String communityId,
    String communityName,
  ) async {
    try {
      final currentUser = _ref.read(userProvider)!;
      final invitation = Invitation(
        id: _uuid.v1(),
        senderUid: currentUser.uid,
        receiverUid: receiverUid,
        type: Constants.membershipInvitationType,
        communityId: communityId,
        createdAt: Timestamp.now(),
      );
      final result = await _invitationRepository.addInvitation(invitation);
      result.fold((l) {
        return left(Failures(l.message));
      }, (r) async {
        final result =
            await _userDeviceController.getUserDeviceTokens(receiverUid);
        result.fold(
          (l) => null,
          (tokens) async {
            await _pushNotificationController.sendPushNotification(
              tokens,
              Constants.getMembershipInvitationContent(
                currentUser.name,
                communityName,
              ),
              Constants.membershipInvitationTitle,
              {
                'type': Constants.membershipInvitationType,
                'communityId': communityId,
              },
              Constants.membershipInvitationType,
            );
            await _notificationController.addNotification(
              receiverUid,
              NotificationModel(
                id: _uuid.v1(),
                title: Constants.membershipInvitationTitle,
                message: Constants.getMembershipInvitationContent(
                  currentUser.name,
                  communityName,
                ),
                communityId: communityId,
                type: Constants.membershipInvitationType,
                senderUid: currentUser.uid,
                createdAt: Timestamp.now(),
                isRead: false,
              ),
            );
          },
        );
        return right(null);
      });
      return result;
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, void>> addModeratorInvitation(
    String receiverUid,
    String communityId,
    String communityName,
  ) async {
    try {
      final currentUser = _ref.read(userProvider)!;
      final invitation = Invitation(
        id: _uuid.v1(),
        senderUid: currentUser.uid,
        receiverUid: receiverUid,
        type: Constants.moderatorInvitationType,
        communityId: communityId,
        createdAt: Timestamp.now(),
      );
      final result = await _invitationRepository.addInvitation(invitation);
      result.fold((l) {
        return left(Failures(l.message));
      }, (r) async {
        final result =
            await _userDeviceController.getUserDeviceTokens(receiverUid);
        result.fold(
          (l) => null,
          (tokens) async {
            await _pushNotificationController.sendPushNotification(
              tokens,
              Constants.getModeratorInvitationContent(
                currentUser.name,
                communityName,
              ),
              Constants.moderatorInvitationTitle,
              {
                'type': Constants.moderatorInvitationType,
                'invitationId': invitation.id,
                'communityId': communityId,
              },
              Constants.moderatorInvitationType,
            );
            await _notificationController.addNotification(
              receiverUid,
              NotificationModel(
                id: _uuid.v1(),
                title: Constants.moderatorInvitationTitle,
                message: Constants.getModeratorInvitationContent(
                  currentUser.name,
                  communityName,
                ),
                communityId: communityId,
                type: Constants.moderatorInvitationType,
                senderUid: currentUser.uid,
                createdAt: Timestamp.now(),
                isRead: false,
              ),
            );
          },
        );
        return right(null);
      });
      return result;
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<Invitation?> fetchInvitation(
    String communityId,
  ) {
    try {
      final currentUser = _ref.read(userProvider)!;
      return _invitationRepository.fetchInvitation(
        currentUser.uid,
        communityId,
      );
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  Future<Either<Failures, void>> deleteInvitation(String invitationId) async {
    try {
      await _invitationRepository.deleteInvitation(invitationId);
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }
}
