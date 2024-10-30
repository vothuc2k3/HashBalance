import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/splash/splash_screen.dart';

import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/call/controller/call_controller.dart';
import 'package:hash_balance/features/call/screen/outgoing_call_screen.dart';
import 'package:hash_balance/features/message/controller/message_controller.dart';
import 'package:hash_balance/features/message/screen/widget/message_bubble.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/message_model.dart';
import 'package:hash_balance/models/user_model.dart';

class PrivateMessageScreen extends ConsumerStatefulWidget {
  final UserModel _targetUser;

  const PrivateMessageScreen({
    super.key,
    required UserModel targetUser,
  }) : _targetUser = targetUser;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PrivateMessageScreenState();
}

class _PrivateMessageScreenState extends ConsumerState<PrivateMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isEmojiVisible = false;
  bool _isLoadingMoreMessages = false;
  List<Message> _messages = [];
  Message? _lastMessage;
  UserModel? currentUser;

  void _showPrivateMessageOptions() {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(
          overlay.localToGlobal(Offset.zero),
          overlay.localToGlobal(overlay.size.bottomRight(Offset.zero)),
        ),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(
          value: 'block',
          child: Text('Block'),
        ),
        const PopupMenuItem(
          value: 'report',
          child: Text('Report'),
        ),
      ],
    ).then(
      (value) {
        if (value == 'block') {
        } else if (value == 'report') {}
      },
    );
  }

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
        .loadMorePrivateMessages(
          getUids(widget._targetUser.uid, currentUser!.uid),
          _lastMessage!,
        );

    if (moreMessages != null && moreMessages.isNotEmpty) {
      setState(() {
        _messages.addAll(moreMessages);
        _lastMessage = moreMessages.last;
      });
    }

    setState(() {
      _isLoadingMoreMessages = false;
    });
  }

  void _onSendMessage(String targetUid) async {
    final result = await ref
        .read(messageControllerProvider.notifier)
        .sendPrivateMessage(_messageController.text, targetUid);
    result.fold(
      (l) {
        showToast(false, l.message);
      },
      (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _messageController.clear();
          FocusManager.instance.primaryFocus?.unfocus();
        });
      },
    );
  }

  void _onStartVoiceCall() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SplashScreen(),
      ),
    );
    final result = await ref
        .read(callControllerProvider.notifier)
        .initCall(widget._targetUser);
    result.fold(
      (l) {
        showToast(
          false,
          l.message,
        );
        Navigator.pop(context);
      },
      (r) async {
        final result =
            await ref.read(callControllerProvider.notifier).fetchCallData(r);
        result.fold(
          (l) => showToast(false, l.message),
          (r) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => OutgoingCallScreen(callData: r),
                ),
              );
            }
          },
        );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => _onStartVoiceCall(),
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showPrivateMessageOptions,
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
                  .watch(initialPrivateMessagesProvider(widget._targetUser.uid))
                  .when(
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

                      _messages = messages;
                      _lastMessage = _messages.last;

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

                          final currentMessageUserId = chatMessage.uid;
                          final nextMessageUserId = nextChatMessage?.uid;
                          final nextUserIsSame =
                              nextMessageUserId == currentMessageUserId;
                          final isMe = currentUser.uid == currentMessageUserId;

                          if (nextUserIsSame) {
                            return MessageBubble.next(
                              message: chatMessage.text ?? '',
                              isMe: isMe,
                            );
                          } else {
                            return MessageBubble.first(
                              userImage: isMe
                                  ? currentUser.profileImage
                                  : widget._targetUser.profileImage,
                              username: isMe
                                  ? currentUser.name
                                  : widget._targetUser.name,
                              message: chatMessage.text ?? '',
                              isMe: isMe,
                            );
                          }
                        },
                      );
                    },
                    loading: () => const Loading(),
                    error: (error, stackTrace) => ErrorText(
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
                      _onSendMessage(widget._targetUser.uid);
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
