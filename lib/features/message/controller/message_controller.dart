import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/message/repository/message_repository.dart';
import 'package:hash_balance/models/conversation_model.dart';
import 'package:hash_balance/models/message_model.dart';

final getCurrentUserConversationProvider = StreamProvider((ref) {
  return ref
      .watch(messageControllerProvider.notifier)
      .getCurrentUserConversation();
});

final loadMessagesProvider = StreamProvider.family((ref, String targetUid) {
  return ref.watch(messageControllerProvider.notifier).loadMessages(targetUid);
});

final getLastMessageByConversationProvider =
    StreamProvider.family((ref, String id) {
  return ref
      .watch(messageControllerProvider.notifier)
      .getLastMessageByConversation(id);
});

final messageControllerProvider =
    StateNotifierProvider<MessageController, bool>(
  (ref) => MessageController(
      messageRepository: ref.read(messageRepositoryProvider), ref: ref),
);

class MessageController extends StateNotifier<bool> {
  final MessageRepository _messageRepository;
  final Ref _ref;

  MessageController({
    required MessageRepository messageRepository,
    required Ref ref,
  })  : _messageRepository = messageRepository,
        _ref = ref,
        super(false);

  Stream<List<Message>?> loadMessages(String targetUid) {
    try {
      final uid = _ref.read(userProvider)!.uid;
      var ids = [targetUid, uid];
      ids.sort();
      final conversationId = ids.join('_');
      return _messageRepository.loadMessages(conversationId);
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  FutureVoid sendMessage(String text, String targetUid) async {
    state = true;
    try {
      final uid = _ref.read(userProvider)!.uid;
      var ids = [targetUid, uid];
      ids.sort();
      _messageRepository.sendMessage(
        Message(
          text: text,
          uid: uid,
          createdAt: Timestamp.now(),
        ),
        Conversation(
          id: ids.join('_'),
          participantUids: [targetUid, uid],
        ),
      );
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    } finally {
      state = false;
    }
  }

  Stream<List<Conversation>?> getCurrentUserConversation() {
    final uid = _ref.read(userProvider)!.uid;
    return _messageRepository.getCurrentUserConversation(uid);
  }
  
  Stream<Message> getLastMessageByConversation(String id) {
    return _messageRepository.getLastMessageByConversation(id);
  }
}
