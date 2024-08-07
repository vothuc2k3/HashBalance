import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/call/controller/voice_call_controller.dart';
import 'package:hash_balance/features/call/screen/call_screen.dart';

import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/message/controller/message_controller.dart';
import 'package:hash_balance/features/message/screen/widget/message_bubble.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:flutter/foundation.dart' as foundation;

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

  bool _isEmojiVisible = false;

  void _onEmojiSelected(Emoji emoji) {
    setState(() {
      _messageController.text += emoji.emoji;
    });
  }

  void onSendMessage(String targetUid) async {
    final result = await ref
        .watch(messageControllerProvider.notifier)
        .sendMessage(_messageController.text, targetUid);
    result.fold(
      (l) {
        showToast(false, l.message);
      },
      (_) {},
    );
  }

  void markAsRead() {
    ref
        .read(messageControllerProvider.notifier)
        .markAsRead(widget._targetUser.uid);
  }

  void onStartVoiceCall(String currentUid) async {
    final result = await ref
        .watch(voiceCallControllerProvider.notifier)
        .fetchAgoraToken(getUids(currentUid, widget._targetUser.uid));
    result.fold((l) => showToast(false, l.message), (r) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(
            caller: ref.watch(userProvider)!,
            receiver: widget._targetUser,
            token: r,
          ),
        ),
      );
    });
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
    final currentUser = ref.watch(userProvider)!;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(widget._targetUser.profileImage),
            ),
            const SizedBox(width: 10),
            Text(
              widget._targetUser.name,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => onStartVoiceCall(currentUser.uid),
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {},
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
                                isMe: currentUser.uid == currentMessageUserId,
                              );
                            } else {
                              return MessageBubble.first(
                                userImage: user.profileImage,
                                username: user.name,
                                message: chatMessage.text,
                                isMe: currentUser.uid == currentMessageUserId,
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
          if (_isEmojiVisible)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _onEmojiSelected(emoji);
                },
                config: Config(
                  height: 256,
                  checkPlatformCompatibility: true,
                  emojiViewConfig: EmojiViewConfig(
                    emojiSizeMax: 28 *
                        (foundation.defaultTargetPlatform == TargetPlatform.iOS
                            ? 1.20
                            : 1.0),
                  ),
                  swapCategoryAndBottomBar: false,
                  skinToneConfig: const SkinToneConfig(),
                  categoryViewConfig: const CategoryViewConfig(),
                  bottomActionBarConfig: const BottomActionBarConfig(),
                  searchViewConfig: const SearchViewConfig(),
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
                                  setState(() {
                                    _isEmojiVisible = !_isEmojiVisible;
                                  });
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
                              onTap: () {
                                if (_isEmojiVisible) {
                                  setState(() {
                                    _isEmojiVisible = false;
                                  });
                                }
                              },
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
                    onSendMessage(widget._targetUser.uid);
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
