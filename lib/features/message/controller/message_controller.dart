import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/message/repository/message_repository.dart';
import 'package:hash_balance/models/message_model.dart';

final loadMessagesProvider = StreamProvider.family((ref, String targetUid) {
  return ref.watch(messageControllerProvider.notifier).loadMessages(targetUid);
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
    final uid = _ref.watch(userProvider)!.uid;
    var ids = [targetUid, uid];
    ids.sort();
    final conversationId = ids.join('_');
    return _messageRepository.loadMessages(conversationId);
  }
}
