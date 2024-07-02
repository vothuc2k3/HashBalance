import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/friends/repository/friend_repository.dart';
import 'package:hash_balance/features/notification/controller/notification_controller.dart';
import 'package:hash_balance/models/friend_model.dart';
import 'package:hash_balance/models/friend_request_model.dart';
import 'package:hash_balance/models/notification_model.dart';
import 'package:hash_balance/models/user_model.dart';

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
          notificationController:
              ref.read(notificationControllerProvider.notifier),
          friendRepository: ref.read(friendRepositoryProvider),
          ref: ref,
        ));

class FriendController extends StateNotifier<bool> {
  final NotificationController _notificationController;
  final FriendRepository _friendRepository;
  final Ref _ref;

  FriendController({
    required NotificationController notificationController,
    required FriendRepository friendRepository,
    required Ref ref,
  })  : _notificationController = notificationController,
        _friendRepository = friendRepository,
        _ref = ref,
        super(false);

  //SEND FRIEND REQUEST
  FutureVoid sendFriendRequest(UserModel targetUser) async {
    try {
      final sender = _ref.watch(userProvider);
      final requestUid = _ref.watch(userProvider)!.uid;
      final targetUid = targetUser.uid;
      var ids = [requestUid, targetUid];
      ids.sort();
      final requestId = ids.join('_');

      final request = FriendRequest(
        id: requestId,
        requestUid: requestUid,
        targetUid: targetUid,
        createdAt: Timestamp.now(),
      );
      await _friendRepository.sendFriendRequest(request);
      await _notificationController.addNotification(
        targetUser.uid,
        NotificationModel(
          id: generateRandomId(),
          title: Constants.friendRequestTitle,
          message: Constants.getFriendRequestContent(sender!.name),
          createdAt: Timestamp.now(),
        ),
      );

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

      //SEND ACCEPT FRIEND REQUEST NOTIFICATION
      await _ref.watch(notificationControllerProvider.notifier).addNotification(
            targetUser.uid,
            NotificationModel(
              id: generateRandomId(),
              title: Constants.acceptRequestTitle,
              message: Constants.getAcceptRequestContent(currentUser.name),
              createdAt: Timestamp.now(),
            ),
          );

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
}
