import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      .collection('conversation')
      .doc(community.id)
      .collection('message')
      .orderBy('createdAt', descending: true)
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
  bool _isEmojiVisible = false;
  bool _isLoadingMore = false;
  List<Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.atEdge &&
          _scrollController.position.pixels == 0) {
        _loadMoreMessages();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
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
      },
    );
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    final lastMessage = _messages.isNotEmpty ? _messages.last : null;

    final moreMessagesSnapshot = await FirebaseFirestore.instance
        .collection('conversation')
        .doc(widget._community.id)
        .collection('message')
        .orderBy('createdAt', descending: true)
        .startAfter([lastMessage?.createdAt])
        .limit(20)
        .get();

    final moreMessages = moreMessagesSnapshot.docs
        .map((doc) => Message.fromMap(doc.data()))
        .toList();

    setState(() {
      _messages.addAll(moreMessages);
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

                      _messages = messages;

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 15,
                        ),
                        reverse: true,
                        itemCount: _messages.length,
                        itemBuilder: (ctx, index) {
                          final chatMessage = _messages[index];
                          final nextChatMessage = index + 1 < _messages.length
                              ? _messages[index + 1]
                              : null;

                          final currentMessageUserId = chatMessage.uid;
                          final nextMessageUserId = nextChatMessage?.uid;
                          final nextUserIsSame =
                              nextMessageUserId == currentMessageUserId;

                          return ref
                              .watch(getUserDataProvider(chatMessage.uid))
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
                    loading: () => _messages.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 15,
                            ),
                            reverse: true,
                            itemCount: _messages.length,
                            itemBuilder: (ctx, index) {
                              final chatMessage = _messages[index];
                              final nextChatMessage =
                                  index + 1 < _messages.length
                                      ? _messages[index + 1]
                                      : null;

                              final currentMessageUserId = chatMessage.uid;
                              final nextMessageUserId = nextChatMessage?.uid;
                              final nextUserIsSame =
                                  nextMessageUserId == currentMessageUserId;

                              return ref
                                  .watch(getUserDataProvider(chatMessage.uid))
                                  .whenOrNull(
                                data: (user) {
                                  if (nextUserIsSame) {
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
                              );
                            },
                          ),
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
