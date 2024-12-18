import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/message/repository/message_repository.dart';
import 'package:hash_balance/features/push_notification/controller/push_notification_controller.dart';
import 'package:hash_balance/features/user_devices/controller/user_device_controller.dart';
import 'package:hash_balance/models/archived_conversation_model.dart';
import 'package:hash_balance/models/conbined_models/message_data_model.dart';
import 'package:hash_balance/models/conversation_model.dart';
import 'package:hash_balance/models/conbined_models/last_message_data_model.dart';
import 'package:hash_balance/models/message_model.dart';
import 'package:hash_balance/models/notification_model.dart';
import 'package:uuid/uuid.dart';

final getArchivedConversationsProvider = StreamProvider((ref) {
  return ref
      .watch(messageControllerProvider.notifier)
      .getArchivedConversations();
});

final getCurrentUserConversationsProvider = StreamProvider.autoDispose((ref) {
  return ref
      .watch(messageControllerProvider.notifier)
      .getCurrentUserConversations();
});

final initialPrivateMessagesProvider =
    StreamProvider.family.autoDispose((ref, String targetUid) {
  return ref
      .watch(messageControllerProvider.notifier)
      .loadInitialPrivateMessages(targetUid);
});

final initialCommunityMessagesProvider =
    FutureProvider.family((ref, String communityId) {
  return ref
      .read(messageControllerProvider.notifier)
      .loadInitialCommunityMessages(communityId)
      .first;
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
      pushNotificationController:
          ref.read(pushNotificationControllerProvider.notifier),
      userDeviceController: ref.read(userDeviceControllerProvider),
      ref: ref),
);

class MessageController extends StateNotifier<bool> {
  final MessageRepository _messageRepository;
  final PushNotificationController _pushNotificationController;
  final UserDeviceController _userDeviceController;
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  MessageController({
    required MessageRepository messageRepository,
    required PushNotificationController pushNotificationController,
    required UserDeviceController userDeviceController,
    required Ref ref,
  })  : _messageRepository = messageRepository,
        _pushNotificationController = pushNotificationController,
        _userDeviceController = userDeviceController,
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

  Future<List<MessageDataModel>?> loadMoreCommunityMessages(
      String conversationId, Message lastMessage) async {
    return _messageRepository.loadMoreCommunityMessages(
      conversationId,
      lastMessage,
    );
  }

  Future<Either<Failures, void>> sendPrivateMessage(
    String text,
    String targetUid,
  ) async {
    try {
      final currentUser = _ref.read(userProvider)!;
      final message = Message(
        id: _uuid.v4(),
        text: text,
        uid: currentUser.uid,
        createdAt: Timestamp.now(),
      );

      final conversationId = getUids(currentUser.uid, targetUid);
      final result = await _messageRepository.sendPrivateMessage(
        message: message,
        conversationId: conversationId,
        targetUid: targetUid,
      );

      if (result.isRight()) {
        final notif = NotificationModel(
          id: _uuid.v1(),
          title: currentUser.name,
          message: text,
          targetUid: targetUid,
          senderUid: currentUser.uid,
          type: Constants.incomingMessageType,
          createdAt: Timestamp.now(),
          isRead: false,
        );

        final deviceTokensResult =
            await _userDeviceController.getUserDeviceTokens(targetUid);
        deviceTokensResult.fold(
          (l) => throw FirebaseException(
            plugin: 'Firebase Exception',
            message: l.message,
          ),
          (tokens) async {
            await _pushNotificationController.sendPushNotification(
              tokens,
              notif.message,
              notif.title,
              {
                'type': Constants.incomingMessageType,
                'uid': currentUser.uid,
              },
              Constants.incomingMessageType,
            );
          },
        );
      }
      return result;
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

  Future<Either<Failures, void>> sendCommunityMessage({
    required String text,
    required String communityId,
  }) async {
    try {
      final currentUser = _ref.watch(userProvider)!;

      final message = Message(
        id: const Uuid().v4(),
        text: text,
        uid: currentUser.uid,
        createdAt: Timestamp.now(),
      );

      return await _messageRepository.sendCommunityMessage(
        message: message,
        communityId: communityId,
      );
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<List<Conversation>> getCurrentUserConversations() {
    final uid = _ref.read(userProvider)!.uid;
    return _messageRepository.getCurrentUserConversations(uid);
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

  Stream<List<Conversation>> getArchivedConversations() {
    final currentUser = _ref.read(userProvider)!.uid;
    return _messageRepository.getArchivedConversations(uid: currentUser);
  }

  Future<Either<Failures, void>> archiveConversation({
    required String conversationId,
  }) async {
    final currentUser = _ref.read(userProvider)!;
    final archivedConversation = ArchivedConversationModel(
      id: _uuid.v1(),
      archivedBy: currentUser.uid,
      conversationId: conversationId,
    );
    return await _messageRepository.archiveConversation(
        archivedConversation: archivedConversation);
  }

  Future<Either<Failures, void>> unarchiveConversation({
    required String conversationId,
  }) async {
    final currentUser = _ref.read(userProvider)!;
    return await _messageRepository.unarchiveConversation(
        conversationId: conversationId, uid: currentUser.uid);
  }
}
