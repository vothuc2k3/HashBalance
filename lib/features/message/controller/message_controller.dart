import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/message/repository/message_repository.dart';
import 'package:hash_balance/features/push_notification/controller/push_notification_controller.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/models/conbined_models/message_data_model.dart';
import 'package:hash_balance/models/conversation_model.dart';
import 'package:hash_balance/models/conbined_models/last_message_data_model.dart';
import 'package:hash_balance/models/message_model.dart';
import 'package:hash_balance/models/notification_model.dart';

final getCurrentUserConversationProvider = StreamProvider((ref) {
  return ref
      .watch(messageControllerProvider.notifier)
      .getCurrentUserConversation();
});

final initialPrivateMessagesProvider =
    StreamProvider.family.autoDispose((ref, String targetUid) {
  return ref
      .watch(messageControllerProvider.notifier)
      .loadInitialPrivateMessages(targetUid);
});

final initialCommunityMessagesProvider =
    StreamProvider.family.autoDispose((ref, String communityId) {
  return ref
      .watch(messageControllerProvider.notifier)
      .loadInitialCommunityMessages(communityId);
});

final getLastMessageByConversationProvider =
    StreamProvider.family((ref, Conversation conversation) {
  return ref
      .watch(messageControllerProvider.notifier)
      .getLastMessageByConversation(conversation);
});

final messageControllerProvider =
    StateNotifierProvider<MessageController, bool>(
  (ref) => MessageController(
      messageRepository: ref.read(messageRepositoryProvider),
      pushNotificationController: ref.watch(
        pushNotificationControllerProvider.notifier,
      ),
      userController: ref.watch(
        userControllerProvider.notifier,
      ),
      ref: ref),
);

class MessageController extends StateNotifier<bool> {
  final MessageRepository _messageRepository;
  final PushNotificationController _pushNotificationController;
  final UserController _userController;
  final Ref _ref;

  MessageController({
    required MessageRepository messageRepository,
    required PushNotificationController pushNotificationController,
    required UserController userController,
    required Ref ref,
  })  : _messageRepository = messageRepository,
        _pushNotificationController = pushNotificationController,
        _userController = userController,
        _ref = ref,
        super(false);

  Stream<List<Message>?> loadInitialPrivateMessages(String targetUid) {
    try {
      final uid = _ref.read(userProvider)!.uid;
      final uids = getUids(uid, targetUid);
      return _messageRepository.loadInitialPrivateMessages(uids);
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  Stream<List<MessageDataModel>?> loadInitialCommunityMessages(
      String communityId) {
    return _messageRepository.loadInitialCommunityMessages(communityId);
  }

  Future<List<Message>?> loadMoreCommunityMessages(
      String conversationId, Message lastMessage) async {
    return _messageRepository.loadMoreCommunityMessages(
      conversationId,
      lastMessage,
    );
  }

  FutureVoid sendPrivateMessage(String text, String targetUid) async {
    try {
      final currentUser = _ref.watch(userProvider)!;
      await _messageRepository.sendPrivateMessage(
        Message(
          id: await generateRandomId(),
          text: text,
          uid: currentUser.uid,
          createdAt: Timestamp.now(),
        ),
        Conversation(
          id: getUids(currentUser.uid, targetUid),
          type: 'Private',
          participantUids: [targetUid, currentUser.uid],
        ),
      );
      final notif = NotificationModel(
        id: await generateRandomId(),
        title: currentUser.name,
        message: text,
        targetUid: targetUid,
        senderUid: currentUser.uid,
        type: Constants.incomingMessageType,
        createdAt: Timestamp.now(),
        isRead: false,
      );
      final targetUserDeviceIds =
          await _userController.getUserDeviceTokens(targetUid);
      await _pushNotificationController.sendPushNotification(
        targetUserDeviceIds,
        notif.message,
        notif.title,
        {
          'type': Constants.incomingMessageType,
          'uid': currentUser.uid,
        },
        Constants.incomingMessageType,
      );
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<List<Message>?> loadMorePrivateMessages(
      String conversationId, Message lastMessage) async {
    return _messageRepository.loadMorePrivateMessages(
      conversationId,
      lastMessage,
    );
  }

  FutureVoid sendCommunityMessage(String text, String communityId) async {
    try {
      final currentUser = _ref.watch(userProvider)!;
      await _messageRepository.sendCommunityMessage(
        Message(
          id: await generateRandomId(),
          text: text,
          uid: currentUser.uid,
          createdAt: Timestamp.now(),
        ),
        Conversation(
          id: communityId,
          type: 'Community',
          participantUids: [currentUser.uid],
        ),
      );
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<List<Conversation>?> getCurrentUserConversation() {
    final uid = _ref.read(userProvider)!.uid;
    return _messageRepository.getCurrentUserConversation(uid);
  }

  Stream<LastMessageDataModel> getLastMessageByConversation(
      Conversation conversation) {
    final currentUid = _ref.read(userProvider)!.uid;
    return _messageRepository.getLastMessageByConversation(
        conversation, currentUid);
  }

  void markAsRead(String targetUid) {
    final currentUser = _ref.watch(userProvider);
    String conversationId = getUids(currentUser!.uid, targetUid);
    _messageRepository.markAsRead(conversationId, currentUser.uid);
  }
}
