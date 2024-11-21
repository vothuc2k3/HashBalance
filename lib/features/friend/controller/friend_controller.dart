import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/friend/repository/friend_repository.dart';
import 'package:hash_balance/features/notification/controller/notification_controller.dart';
import 'package:hash_balance/features/push_notification/controller/push_notification_controller.dart';
import 'package:hash_balance/features/user_devices/controller/user_device_controller.dart';
import 'package:hash_balance/models/conbined_models/block_data_model.dart';
import 'package:hash_balance/models/conbined_models/friend_requester_data_model.dart';
import 'package:hash_balance/models/conbined_models/mutual_friend_model.dart';
import 'package:hash_balance/models/follower_model.dart';
import 'package:hash_balance/models/friendship_model.dart';
import 'package:hash_balance/models/friendship_request_model.dart';
import 'package:hash_balance/models/notification_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

final mutualFriendsProvider =
    FutureProvider.family((ref, Tuple2<String, String> data) {
  return ref.watch(friendControllerProvider.notifier).getMutualFriends(
        data.item1,
        data.item2,
      );
});

final mutualFriendsCountProvider =
    FutureProvider.family((ref, Tuple2<String, String> data) {
  return ref.watch(friendControllerProvider.notifier).getMutualFriendsCount(
        data.item1,
        data.item2,
      );
});

final blockedUsersProvider = StreamProvider((ref) {
  return ref.watch(friendControllerProvider.notifier).fetchBlockedUsers();
});

final isBlockedByCurrentUserProvider =
    StreamProvider.family((ref, Tuple2 data) {
  return ref.watch(friendControllerProvider.notifier).isBlockedByCurrentUser(
        currentUid: data.item1,
        blockUid: data.item2,
      );
});

final isBlockedByTargetUserProvider = StreamProvider.family((ref, Tuple2 data) {
  return ref.watch(friendControllerProvider.notifier).isBlockedByTargetUser(
        currentUid: data.item1,
        targetUid: data.item2,
      );
});

final getCombinedStatusProvider = StreamProvider.family((ref, Tuple2 data) {
  return ref.watch(friendControllerProvider.notifier).getCombinedStatus(
        currentUid: data.item1,
        targetUid: data.item2,
      );
});

final fetchFriendRequestsProvider = StreamProvider.family((ref, String uid) {
  return ref
      .watch(friendControllerProvider.notifier)
      .fetchFriendRequestsByUser(uid);
});

final fetchFriendsProvider = FutureProvider.family((ref, String uid) {
  return ref.watch(friendControllerProvider.notifier).fetchFriendsByUser(uid);
});

final getFollowingStatusProvider =
    StreamProvider.family((ref, String targetUid) {
  return ref
      .watch(friendControllerProvider.notifier)
      .getFollowingStatus(targetUid);
});

final getFriendshipStatusProvider =
    StreamProvider.family((ref, String targetUid) {
  return ref
      .watch(friendControllerProvider.notifier)
      .getFriendshipStatus(targetUid);
});

final getFriendRequestStatusProvider =
    StreamProvider.family((ref, String requestId) {
  return ref
      .watch(friendControllerProvider.notifier)
      .getFriendRequestStatus(requestId);
});

final friendControllerProvider =
    StateNotifierProvider<FriendController, bool>((ref) => FriendController(
          userDeviceController: ref.read(userDeviceControllerProvider),
          notificationController:
              ref.read(notificationControllerProvider.notifier),
          friendRepository: ref.read(friendRepositoryProvider),
          ref: ref,
          pushNotificationController:
              ref.read(pushNotificationControllerProvider.notifier),
        ));

class FriendController extends StateNotifier<bool> {
  final NotificationController _notificationController;
  final FriendRepository _friendRepository;
  final PushNotificationController _pushNotificationController;
  final UserDeviceController _userDeviceController;
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  FriendController({
    required UserDeviceController userDeviceController,
    required PushNotificationController pushNotificationController,
    required NotificationController notificationController,
    required FriendRepository friendRepository,
    required Ref ref,
  })  : _notificationController = notificationController,
        _friendRepository = friendRepository,
        _userDeviceController = userDeviceController,
        _pushNotificationController = pushNotificationController,
        _ref = ref,
        super(false);

  //SEND FRIEND REQUEST
  Future<Either<Failures, void>> sendFriendRequest(UserModel targetUser) async {
    try {
      final sender = _ref.read(userProvider)!;
      final request = FriendRequest(
        id: getUids(sender.uid, targetUser.uid),
        requestUid: sender.uid,
        targetUid: targetUser.uid,
        createdAt: Timestamp.now(),
        status: Constants.friendRequestStatusPending,
      );
      await _friendRepository.sendFriendRequest(request);
      final notif = NotificationModel(
        id: _uuid.v1(),
        title: Constants.friendRequestTitle,
        message: Constants.getFriendRequestContent(sender.name),
        targetUid: targetUser.uid,
        senderUid: sender.uid,
        type: Constants.friendRequestType,
        createdAt: Timestamp.now(),
        isRead: false,
      );

      //SEND PUSH NOTIFICATION TO THE TARGET
      final result =
          await _userDeviceController.getUserDeviceTokens(targetUser.uid);
      result.fold(
          (l) => throw FirebaseException(
                plugin: 'Firebase Exception',
                message: l.message,
              ), (tokens) async {
        await _pushNotificationController.sendPushNotification(
          tokens,
          notif.message,
          notif.title,
          {
            'type': Constants.friendRequestType,
            'uid': sender.uid,
          },
          Constants.friendRequestType,
        );
      });

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
  Future<Either<Failures, void>> cancelFriendRequest(String requestId) async {
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
  Future<Either<Failures, void>> acceptFriendRequest(
      UserModel targetUser) async {
    try {
      final currentUser = _ref.watch(userProvider);
      final requestId = getUids(currentUser!.uid, targetUser.uid);
      await _friendRepository.acceptFriendRequest(
        Friendship(
          uid1: currentUser.uid,
          uid2: targetUser.uid,
          createdAt: Timestamp.now(),
        ),
      );
      await _friendRepository.cancelFriendRequest(requestId);
      final notif = NotificationModel(
        id: _uuid.v1(),
        title: Constants.acceptRequestTitle,
        message: Constants.getAcceptRequestContent(currentUser.name),
        targetUid: targetUser.uid,
        senderUid: currentUser.uid,
        type: Constants.acceptRequestType,
        createdAt: Timestamp.now(),
        isRead: false,
      );
      //SEND ACCEPT REQUEST PUSH NOTIFICATION
      final result =
          await _userDeviceController.getUserDeviceTokens(targetUser.uid);
      result.fold(
          (l) => throw FirebaseException(
                plugin: 'Firebase Exception',
                message: l.message,
              ), (tokens) async {
        await _pushNotificationController.sendPushNotification(
          tokens,
          notif.message,
          notif.title,
          {
            'type': Constants.acceptRequestType,
            'uid': currentUser.uid,
          },
          Constants.acceptRequestType,
        );
      });
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

  Future<Either<Failures, void>> declineFriendRequest(
      UserModel targetUser) async {
    try {
      final currentUser = _ref.watch(userProvider);
      await _friendRepository
          .declineFriendRequest(getUids(currentUser!.uid, targetUser.uid));
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, void>> unfriend(String targetUid) async {
    try {
      final currentUser = _ref.watch(userProvider);
      await _friendRepository.unfriend(getUids(targetUid, currentUser!.uid));
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<bool> getFriendshipStatus(String targetUid) {
    try {
      final currentUser = _ref.read(userProvider);
      return _friendRepository.getFriendshipStatus(
        uids: getUids(currentUser!.uid, targetUid),
      );
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  Future<List<UserModel>> fetchFriendsByUser(String uid) async {
    return await _friendRepository.fetchFriendsByUser(uid);
  }

  Future<Either<Failures, void>> followUser(String targetUid) async {
    try {
      final currentUser = _ref.read(userProvider)!;
      final followerModel = Follower(
        id: _uuid.v1(),
        followerUid: currentUser.uid,
        targetUid: targetUid,
        createdAt: Timestamp.now(),
      );
      await _friendRepository.followUser(followerModel);

      final notif = NotificationModel(
        id: _uuid.v1(),
        title: Constants.newFollowerTitle,
        message: Constants.getNewFollowerContent(currentUser.name),
        targetUid: targetUid,
        senderUid: currentUser.uid,
        type: Constants.newFollowerType,
        createdAt: Timestamp.now(),
        isRead: false,
      );

      //SEND A NOTIFICATION TO THE TARGET USER
      await _notificationController.addNotification(targetUid, notif);

      //SEND NEW FOLLOWER PUSH NOTIFICATION
      final result = await _userDeviceController.getUserDeviceTokens(targetUid);
      result.fold(
          (l) => throw FirebaseException(
                plugin: 'Firebase Exception',
                message: l.message,
              ), (tokens) async {
        await _pushNotificationController.sendPushNotification(
          tokens,
          notif.message,
          notif.title,
          {
            'type': Constants.newFollowerType,
            'uid': currentUser.uid,
          },
          Constants.newFollowerType,
        );
      });

      return right(null);
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  Future<Either<Failures, void>> unfollowUser(String targetUid) async {
    try {
      final uid = _ref.read(userProvider)!.uid;
      await _friendRepository.unfollowUser(uid, targetUid);
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    }
  }

  Stream<bool> getFollowingStatus(String targetUid) {
    final uid = _ref.read(userProvider)!.uid;
    return _friendRepository.getFollowingStatus(
      currentUid: uid,
      targetUid: targetUid,
    );
  }

  Stream<List<FriendRequesterDataModel>> fetchFriendRequestsByUser(String uid) {
    return _friendRepository.fetchFriendRequestsByUser(uid);
  }

  Stream<bool> isBlockedByCurrentUser({
    required String currentUid,
    required String blockUid,
  }) {
    return _friendRepository.isBlockedByCurrentUser(
      currentUid: currentUid,
      blockUid: blockUid,
    );
  }

  Stream<Tuple4<bool, bool, bool, bool>> getCombinedStatus({
    required String currentUid,
    required String targetUid,
  }) {
    final uids = getUids(currentUid, targetUid);
    return _friendRepository.getCombinedStatus(
      currentUid: currentUid,
      targetUid: targetUid,
      friendshipUids: uids,
    );
  }

  Stream<List<BlockDataModel>?> fetchBlockedUsers() {
    final currentUid = _ref.read(userProvider)!.uid;
    return _friendRepository.fetchBlockedUsers(currentUid);
  }

  Future<int> getMutualFriendsCount(String uid1, String uid2) async {
    return _friendRepository.getMutualFriendsCount(uid1, uid2);
  }

  Future<List<MutualFriend>> getMutualFriends(String uid1, String uid2) async {
    return await _friendRepository.getMutualFriends(uid1, uid2);
  }

  Future<List<String>> getUserFollowerUids(String uid) async {
    return await _friendRepository.getUserFollowerUids(uid);
  }

  Future<void> notifyFollowers({
    required String uid,
    required String message,
    required String title,
    required String type,
  }) async {
    final followerUids = await getUserFollowerUids(uid);
    final tokens = <String>[];
    for (final followerUid in followerUids) {
      final result =
          await _userDeviceController.getUserDeviceTokens(followerUid);
      result.fold(
          (l) => throw FirebaseException(
                plugin: 'Firebase Exception',
                message: l.message,
              ),
          (tokens) => tokens.addAll(tokens));
    }
    await _pushNotificationController.sendPushNotification(
      tokens,
      message,
      title,
      {
        'type': type,
        'uid': uid,
      },
      type,
    );
  }

  Stream<bool> isBlockedByTargetUser({
    required String currentUid,
    required String targetUid,
  }) {
    return _friendRepository.isBlockedByTargetUser(
      currentUid: currentUid,
      targetUid: targetUid,
    );
  }
}
