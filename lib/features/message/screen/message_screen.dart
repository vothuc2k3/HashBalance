import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/message/controller/message_controller.dart';
import 'package:hash_balance/features/message/screen/widget/message_bubble.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/features/voice_call/controller/voice_call_controller.dart';
import 'package:hash_balance/models/user_model.dart';

class MessageScreen extends ConsumerStatefulWidget {
  final UserModel _targetUser;

  const MessageScreen({
    super.key,
    required UserModel targetUser,
  }) : _targetUser = targetUser;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MessageScreenState();
}

class _MessageScreenState extends ConsumerState<MessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? uids;
  String? token;
  final role = ClientRole.Broadcaster;

  void _init() async {
    final result = await ref
        .watch(voiceCallControllerProvider.notifier)
        .fetchAgoraToken(uids!);
    result.fold((l) => showToast(false, l.message), (r) => token = r);
    uids = getUids(widget._targetUser.uid, ref.read(userProvider)!.uid);
  }

  void sendMessage(String targetUid) async {
    final result = await ref
        .watch(messageControllerProvider.notifier)
        .sendMessage(_messageController.text, targetUid);
    result.fold((l) {
      showToast(false, l.message);
    }, (_) {});
  }

  void markAsRead() {
    ref
        .read(messageControllerProvider.notifier)
        .markAsRead(widget._targetUser.uid);
  }

  @override
  void initState() {
    _init();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      markAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(widget._targetUser.profileImage),
            ),
            const SizedBox(width: 10),
            Text(widget._targetUser.name),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              // Implement video call
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Implement more actions if needed
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ref.watch(loadMessagesProvider(widget._targetUser.uid)).when(
                  data: (messages) {
                    if (messages == null || messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'Text your first message!',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 15,
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
                            .whenOrNull(
                          data: (user) {
                            if (nextUserIsSame) {
                              return MessageBubble.next(
                                message: chatMessage.text,
                                isMe: currentUser!.uid == currentMessageUserId,
                              );
                            } else {
                              return MessageBubble.first(
                                userImage: user.profileImage,
                                username: user.name,
                                message: chatMessage.text,
                                isMe: currentUser!.uid == currentMessageUserId,
                              );
                            }
                          },
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
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 15,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        if (_messageController.text.isEmpty)
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.image,
                                    color: Colors.white),
                                onPressed: () {
                                  // Implement image picker
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.videocam,
                                    color: Colors.white),
                                onPressed: () {
                                  // Implement video picker
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.insert_emoticon,
                                    color: Colors.white),
                                onPressed: () {
                                  // Implement emoji picker
                                },
                              ),
                            ],
                          ),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 15.0),
                            child: TextField(
                              controller: _messageController,
                              textCapitalization: TextCapitalization.sentences,
                              autocorrect: true,
                              enableSuggestions: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Send a message...',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    sendMessage(widget._targetUser.uid);
                    _messageController.clear();
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.teal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
