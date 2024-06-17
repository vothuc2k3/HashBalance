import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/message/controller/message_controller.dart';
import 'package:hash_balance/features/message/screen/widget/message_bubble.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';

class MessageScreen extends ConsumerStatefulWidget {
  final String _targetuid;

  const MessageScreen({
    super.key,
    required String targetuid,
  }) : _targetuid = targetuid;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MessageScreenState();
}

class _MessageScreenState extends ConsumerState<MessageScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FlutterChat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ref.watch(loadMessagesProvider(widget._targetuid)).when(
                  data: (messages) {
                    if (messages == null || messages.isEmpty) {
                      return const Text('Text your fist message!');
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(
                        bottom: 40,
                        left: 13,
                        right: 13,
                      ),
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (ctx, index) {
                        final chatMessage = messages[index];
                        final nextChatMessage = index + 1 < messages.length
                            ? messages[index + 1]
                            : null;

                        final currentMessageUserId = chatMessage.uid;
                        final nextMessageUserId = nextChatMessage?.uid;
                        final nextUserIsSame =
                            nextMessageUserId == currentMessageUserId;

                        return ref
                            .watch(getUserByUidProvider(chatMessage.uid))
                            .when(
                              data: (user) {
                                if (nextUserIsSame) {
                                  return MessageBubble.next(
                                    message: chatMessage.text,
                                    isMe: currentUser!.uid ==
                                        currentMessageUserId,
                                  );
                                } else {
                                  return MessageBubble.first(
                                    userImage: user.profileImage,
                                    username: user.name,
                                    message: chatMessage.text,
                                    isMe: currentUser!.uid ==
                                        currentMessageUserId,
                                  );
                                }
                              },
                              error: (error, stackTrace) =>
                                  ErrorText(error: error.toString()),
                              loading: () => const Loading(),
                            );
                      },
                    );
                  },
                  loading: () => const Loading(),
                  error: (Object error, StackTrace stackTrace) => ErrorText(
                    error: error.toString(),
                  ),
                ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                right: 1,
                left: 15,
                bottom: 14,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: 'Send messages....',
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    child: IconButton(
                      onPressed: () {
                        {}
                      },
                      icon: Icon(
                        Icons.send,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
