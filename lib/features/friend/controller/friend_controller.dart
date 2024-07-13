import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/friend/repository/friend_repository.dart';
import 'package:hash_balance/features/notification/controller/notification_controller.dart';
import 'package:hash_balance/features/push_notification/controller/push_notification_controller.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/models/friendship_model.dart';
import 'package:hash_balance/models/friendship_request_model.dart';
import 'package:hash_balance/models/notification_model.dart';
import 'package:hash_balance/models/user_model.dart';

final fetchFriendsProvider = FutureProvider.family((ref, String uid) async {
  return await ref
      .watch(friendControllerProvider.notifier)
      .fetchFriendsByUser(uid);
});

final getFriendshipStatusProvider =
    StreamProvider.family((ref, UserModel targetUser) {
  return ref
      .watch(friendControllerProvider.notifier)
      .getFriendshipStatus(targetUser);
});

final getFriendRequestStatusProvider =
    StreamProvider.family((ref, String requestId) {
  return ref
      .watch(friendControllerProvider.notifier)
      .getFriendRequestStatus(requestId);
});

final friendControllerProvider =
    StateNotifierProvider<FriendController, bool>((ref) => FriendController(
          userController: ref.read(userControllerProvider.notifier),
          notificationController:
              ref.read(notificationControllerProvider.notifier),
          friendRepository: ref.read(friendRepositoryProvider),
          ref: ref,
          pushNotificationController:
              ref.read(pushNotificationControllerProvider.notifier),
        ));

class FriendController extends StateNotifier<bool> {
  final UserController _userController;
  final PushNotificationController _pushNotificationController;
  final NotificationController _notificationController;
  final FriendRepository _friendRepository;
  final Ref _ref;

  FriendController({
    required UserController userController,
    required PushNotificationController pushNotificationController,
    required NotificationController notificationController,
    required FriendRepository friendRepository,
    required Ref ref,
  })  : _userController = userController,
        _pushNotificationController = pushNotificationController,
        _notificationController = notificationController,
        _friendRepository = friendRepository,
        _ref = ref,
        super(false);

  //SEND FRIEND REQUEST
  FutureVoid sendFriendRequest(UserModel targetUser) async {
    try {
      final sender = _ref.watch(userProvider);
      final requestUid = _ref.watch(userProvider)!.uid;
      final targetUid = targetUser.uid;

      final request = FriendRequest(
        id: getUids(requestUid, targetUid),
        requestUid: requestUid,
        targetUid: targetUid,
        createdAt: Timestamp.now(),
      );
      await _friendRepository.sendFriendRequest(request);

      final notif = NotificationModel(
        id: generateRandomId(),
        title: Constants.friendRequestTitle,
        message: Constants.getFriendRequestContent(sender!.name),
        type: Constants.friendRequestType,
        createdAt: Timestamp.now(),
      );

      //SEND PUSH NOTIFICATION TO THE TARGET
      final targetUserDeviceIds =
          await _userController.getUserDeviceIds(targetUid);
      await _pushNotificationController.sendPushNotification(
          targetUserDeviceIds, targetUid, notif);

      //SEND A NOTIFICATION TO THE TARGET USER
      await _notificationController.addNotification(targetUser.uid, notif);
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //CANCEL FRIEND REQUEST
  FutureVoid cancelFriendRequest(String requestId) async {
    try {
      await _friendRepository.cancelFriendRequest(requestId);
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //GET THE SEND REQUEST STATUS
  Stream<FriendRequest?> getFriendRequestStatus(String uids) {
    try {
      return _friendRepository.getFriendRequestStatus(uids);
    } on FirebaseException catch (e) {
      throw left(Failures(e.message!));
    } catch (e) {
      throw left(Failures(e.toString()));
    }
  }

  //ACCEPT FRIEND REQUEST
  FutureVoid acceptFriendRequest(UserModel targetUser) async {
    try {
      final currentUser = _ref.watch(userProvider);
      await _friendRepository.acceptFriendRequest(
        Friendship(
          uid1: currentUser!.uid,
          uid2: targetUser.uid,
          createdAt: Timestamp.now(),
        ),
      );

      final notif = NotificationModel(
        id: generateRandomId(),
        title: Constants.acceptRequestTitle,
        message: Constants.getAcceptRequestContent(currentUser.name),
        targetUid: targetUser.uid,
        type: Constants.acceptRequestType,
        createdAt: Timestamp.now(),
      );

      //SEND ACCEPT REQUEST PUSH NOTIFICATION
      final targetUserDeviceIds =
          await _userController.getUserDeviceIds(targetUser.uid);
      await _pushNotificationController.sendPushNotification(
        targetUserDeviceIds,
        targetUser.uid,
        notif,
      );

      //SEND ACCEPT FRIEND REQUEST NOTIFICATION
      await _ref
          .watch(notificationControllerProvider.notifier)
          .addNotification(targetUser.uid, notif);

      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  FutureVoid unfriend(UserModel targetUser) async {
    try {
      final currentUser = _ref.watch(userProvider);
      await _friendRepository
          .unfriend(getUids(targetUser.uid, currentUser!.uid));
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<bool> getFriendshipStatus(UserModel targetUser) {
    try {
      final currentUser = _ref.read(userProvider);
      return _friendRepository
          .getFriendshipStatus(getUids(currentUser!.uid, targetUser.uid));
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  Future<List<UserModel>> fetchFriendsByUser(String uid) async {
    return await _friendRepository.fetchFriendsByUser(uid);
  }
}
