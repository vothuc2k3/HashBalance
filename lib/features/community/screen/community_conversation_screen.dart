import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/message/controller/message_controller.dart';
import 'package:hash_balance/features/message/screen/widget/message_bubble.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/conbined_models/message_data_model.dart';
import 'package:hash_balance/models/message_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';

class CommunityConversationScreen extends ConsumerStatefulWidget {
  final Community community;

  const CommunityConversationScreen({
    super.key,
    required this.community,
  });

  @override
  ConsumerState<CommunityConversationScreen> createState() =>
      _CommunityConversationScreenState();
}

class _CommunityConversationScreenState
    extends ConsumerState<CommunityConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isEmojiVisible = false;
  bool _isLoadingMoreMessages = false;
  List<MessageDataModel> _messages = [];
  Message? _lastMessage;
  UserModel? currentUser;
  bool _hasLoadedInitialMessages = false;

  void _onScroll() async {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoadingMoreMessages) {
      await _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_lastMessage == null) return;
    setState(() {
      _isLoadingMoreMessages = true;
    });

    final moreMessages = await ref
        .read(messageControllerProvider.notifier)
        .loadMoreCommunityMessages(widget.community.id, _lastMessage!);

    if (moreMessages != null && moreMessages.isNotEmpty) {
      setState(() {
        _messages.addAll(moreMessages);
        _lastMessage = moreMessages.last.message;
      });
    }

    setState(() {
      _isLoadingMoreMessages = false;
    });
  }

  void _onSendMessage() async {
    final result =
        await ref.read(messageControllerProvider.notifier).sendCommunityMessage(
              text: _messageController.text,
              communityId: widget.community.id,
            );
    result.fold(
      (l) {
        showToast(false, l.message);
      },
      (_) {
        setState(() {
          final newMessage = Message(
            id: const Uuid().v4(),
            text: _messageController.text,
            uid: currentUser!.uid,
            createdAt: Timestamp.now(),
          );
          _messages.insert(
            0,
            MessageDataModel(message: newMessage, author: currentUser!),
          );
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _messageController.clear();
          FocusManager.instance.primaryFocus?.unfocus();
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    currentUser = ref.watch(userProvider);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ref.watch(preferredThemeProvider).second,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(widget.community.profileImage),
            ),
            const SizedBox(width: 10),
            Text(
              widget.community.name,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: ref.watch(preferredThemeProvider).first,
        ),
        child: Column(
          children: [
            Expanded(
              child: ref
                  .read(initialCommunityMessagesProvider(widget.community.id))
                  .when(
                    data: (messages) {
                      if (!_hasLoadedInitialMessages) {
                        _hasLoadedInitialMessages = true;
                        _messages = messages ?? [];
                        if (_messages.isNotEmpty) {
                          _lastMessage = _messages.last.message;
                        }
                      }

                      if (_messages.isEmpty) {
                        return const Center(
                          child: Text(
                            'Start this conversation!',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 15,
                        ),
                        reverse: true,
                        itemCount: _messages.length + 1,
                        itemBuilder: (ctx, index) {
                          if (index == _messages.length) {
                            return _isLoadingMoreMessages
                                ? const Center(child: Loading())
                                : const SizedBox.shrink();
                          }

                          final chatMessage = _messages[index];
                          final nextChatMessage = index + 1 < _messages.length
                              ? _messages[index + 1]
                              : null;

                          final currentMessageUserId = chatMessage.message.uid;
                          final nextMessageUserId =
                              nextChatMessage?.message.uid;
                          final nextUserIsSame =
                              nextMessageUserId == currentMessageUserId;
                          final isMe = currentUser.uid == currentMessageUserId;

                          if (nextUserIsSame) {
                            return MessageBubble.next(
                              message: chatMessage.message.text ?? '',
                              isMe: isMe,
                            );
                          } else {
                            return MessageBubble.first(
                              userImage: isMe
                                  ? currentUser.profileImage
                                  : chatMessage.author.profileImage,
                              username: isMe
                                  ? currentUser.name
                                  : chatMessage.author.name,
                              message: chatMessage.message.text ?? '',
                              isMe: isMe,
                            );
                          }
                        },
                      ).animate().fade(duration: 300.milliseconds);
                    },
                    loading: () => const Loading(),
                    error: (error, stackTrace) => ErrorText(
                      error: error.toString(),
                    ),
                  ),
            ),
            // Ô nhập và nút gửi tin nhắn
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
                                textCapitalization:
                                    TextCapitalization.sentences,
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
                    onTap: _onSendMessage,
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
      ),
    );
  }
}
