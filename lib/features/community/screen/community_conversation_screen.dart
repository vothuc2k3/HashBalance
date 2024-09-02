import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/message/controller/message_controller.dart';
import 'package:hash_balance/features/message/screen/widget/message_bubble.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/message_model.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:cloud_firestore/cloud_firestore.dart';

final communityMessagesProvider =
    StreamProvider.autoDispose.family((ref, Community community) {
  return FirebaseFirestore.instance
      .collection(FirebaseConstants.conversationCollection)
      .doc(community.id)
      .collection(FirebaseConstants.messageCollection)
      .orderBy('createdAt',
          descending: false) // Load messages in ascending order
      .limit(20)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList());
});

class CommunityConversationScreen extends ConsumerStatefulWidget {
  final Community _community;

  const CommunityConversationScreen({
    super.key,
    required Community community,
  }) : _community = community;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CommunityConversationScreenState();
}

class _CommunityConversationScreenState
    extends ConsumerState<CommunityConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<Message> _messages = [];
  bool _isEmojiVisible = false;
  bool _isLoadingMore = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == 0 &&
          !_scrollController.position.atEdge) {
        _loadMoreMessages();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onEmojiSelected(Emoji emoji) {
    setState(() {
      _messageController.text += emoji.emoji;
    });
  }

  void onSendMessage() async {
    final result = await ref
        .watch(messageControllerProvider.notifier)
        .sendCommunityMessage(_messageController.text, widget._community.id);
    result.fold(
      (l) {
        showToast(false, l.message);
      },
      (_) {
        _messageController.clear();
        FocusManager.instance.primaryFocus?.unfocus();
        _scrollToBottom(); // Scroll to bottom after sending message
      },
    );
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    final lastMessage = _messages.isNotEmpty ? _messages.first : null;

    final moreMessagesSnapshot = await FirebaseFirestore.instance
        .collection(FirebaseConstants.conversationCollection)
        .doc(widget._community.id)
        .collection(FirebaseConstants.messageCollection)
        .orderBy('createdAt', descending: false)
        .endBefore([lastMessage?.createdAt])
        .limitToLast(20)
        .get();

    final moreMessages = moreMessagesSnapshot.docs
        .map((doc) => Message.fromMap(doc.data()))
        .toList();

    setState(() {
      _messages.insertAll(0, moreMessages);
      for (var i = 0; i < moreMessages.length; i++) {
        _listKey.currentState?.insertItem(0);
      }
    });

    _isLoadingMore = false;
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
                  CachedNetworkImageProvider(widget._community.profileImage),
            ),
            const SizedBox(width: 10),
            Text(
              widget._community.name,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF000000),
              Color(0xFF0D47A1),
              Color(0xFF1976D2),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ref
                  .watch(communityMessagesProvider(widget._community))
                  .when(
                    data: (messages) {
                      if (messages.isEmpty && _messages.isEmpty) {
                        return Center(
                          child: const Text(
                            'Text your first message!',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ).animate().fadeIn(duration: 800.ms),
                        );
                      }

                      final newMessages = messages
                          .where((message) =>
                              !_messages.any((m) => m.id == message.id))
                          .toList();

                      for (var i = 0; i < newMessages.length; i++) {
                        _messages.add(newMessages[i]);
                        _listKey.currentState?.insertItem(_messages.length - 1);
                      }

                      return AnimatedList(
                        key: _listKey,
                        controller: _scrollController,
                        reverse: false,
                        initialItemCount: _messages.length,
                        itemBuilder: (ctx, index, animation) {
                          final chatMessage = _messages[index];
                          final prevChatMessage =
                              index > 0 ? _messages[index - 1] : null;

                          final currentMessageUserId = chatMessage.uid;
                          final prevMessageUserId = prevChatMessage?.uid;
                          final prevUserIsSame =
                              prevMessageUserId == currentMessageUserId;

                          return SizeTransition(
                            sizeFactor: animation,
                            child: ref
                                .watch(getUserDataProvider(chatMessage.uid))
                                .whenOrNull(
                              data: (user) {
                                if (prevUserIsSame) {
                                  return MessageBubble.next(
                                    message: chatMessage.text,
                                    isMe:
                                        currentUser.uid == currentMessageUserId,
                                  );
                                } else {
                                  return MessageBubble.first(
                                    userImage: user.profileImage,
                                    username: user.name,
                                    message: chatMessage.text,
                                    isMe:
                                        currentUser.uid == currentMessageUserId,
                                  );
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                    loading: () => _messages.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : AnimatedList(
                            key: _listKey,
                            controller: _scrollController,
                            reverse: false,
                            initialItemCount: _messages.length,
                            itemBuilder: (ctx, index, animation) {
                              final chatMessage = _messages[index];
                              final prevChatMessage =
                                  index > 0 ? _messages[index - 1] : null;

                              final currentMessageUserId = chatMessage.uid;
                              final prevMessageUserId = prevChatMessage?.uid;
                              final prevUserIsSame =
                                  prevMessageUserId == currentMessageUserId;

                              return SizeTransition(
                                sizeFactor: animation,
                                child: ref
                                    .watch(getUserDataProvider(chatMessage.uid))
                                    .whenOrNull(
                                  data: (user) {
                                    if (prevUserIsSame) {
                                      return MessageBubble.next(
                                        message: chatMessage.text,
                                        isMe: currentUser.uid ==
                                            currentMessageUserId,
                                      );
                                    } else {
                                      return MessageBubble.first(
                                        userImage: user.profileImage,
                                        username: user.name,
                                        message: chatMessage.text,
                                        isMe: currentUser.uid ==
                                            currentMessageUserId,
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                    error: (error, stackTrace) => ErrorText(
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
                          (foundation.defaultTargetPlatform ==
                                  TargetPlatform.iOS
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
                                focusNode: _focusNode,
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
                    onTap: () {
                      onSendMessage();
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
      ),
    );
  }
}
