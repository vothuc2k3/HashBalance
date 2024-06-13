import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/friends/repository/friend_repository.dart';
import 'package:hash_balance/features/notification/controller/notification_controller.dart';
import 'package:hash_balance/models/friend_request_model.dart';
import 'package:hash_balance/models/user_model.dart';

final getFriendRequestStatusProvider =
    StreamProvider.family((ref, String requestId) {
  return ref
      .watch(friendControllerProvider.notifier)
      .getFriendRequestStatus(requestId);
});

final friendControllerProvider =
    StateNotifierProvider<FriendController, bool>((ref) => FriendController(
          friendRepository: ref.read(friendRepositoryProvider),
          ref: ref,
        ));

class FriendController extends StateNotifier<bool> {
  final FriendRepository _friendRepository;
  final Ref _ref;

  FriendController({
    required FriendRepository friendRepository,
    required Ref ref,
  })  : _friendRepository = friendRepository,
        _ref = ref,
        super(false);

  //SEND FRIEND REQUEST
  FutureVoid sendFriendRequest(UserModel targetUser) async {
    try {
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

      final notificationController =
          _ref.watch(notificationControllerProvider.notifier);
      notificationController.sendNotification(
        targetUid,
        'friend_request',
        'New Friend Request',
        '${targetUser.name} has sent you a friend request.',
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
  Stream<FriendRequest?> getFriendRequestStatus(String requestId) {
    try {
      return _friendRepository.getFriendRequestStatus(requestId);
    } on FirebaseException catch (e) {
      throw left(Failures(e.message!));
    } catch (e) {
      throw left(Failures(e.toString()));
    } finally {
      state = false;
    }
  }

  FutureVoid acceptFriendRequest(UserModel targetUser) async {
    try {
      final currentUser = _ref.watch(userProvider);
      await _friendRepository.acceptFriendRequest(
        currentUser!,
        targetUser,
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
      await _friendRepository.unfriend(
        currentUser!,
        targetUser,
      );
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }
}
