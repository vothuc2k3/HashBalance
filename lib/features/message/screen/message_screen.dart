import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/message/screen/widget/message_bubble.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';

class MessageScreen extends ConsumerStatefulWidget {
  final String _roomId;

  const MessageScreen({
    super.key,
    required String roomId,
  }) : _roomId = roomId;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MessageScreenState();
}

class _MessageScreenState extends ConsumerState<MessageScreen> {
  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final currentUser = ref.watch(userProvider);

    return StreamBuilder(
      stream: firestore
          .collection('messages')
          .where('id', isEqualTo: widget._roomId)
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (ctx, chatSnapshot) {
        if (chatSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
          return const Text('No messages found...');
        }
        if (chatSnapshot.hasError) {
          return const Text('Unexpected error...');
        }

        final loadedMessages = chatSnapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(
            bottom: 40,
            left: 13,
            right: 13,
          ),
          reverse: true,
          itemCount: loadedMessages.length,
          itemBuilder: (ctx, index) {
            final chatMessage = loadedMessages[index].data();
            final nextChatMessage = index + 1 < loadedMessages.length
                ? loadedMessages[index + 1].data()
                : null;

            final currentMessageUserId = chatMessage['uid'];
            final nextMessageUserId =
                nextChatMessage != null ? nextChatMessage['uid'] : null;
            final nextUserIsSame = nextMessageUserId == currentMessageUserId;

            return ref.watch(getUserByUidProvider(chatMessage['uid'])).when(
                  data: (user) {
                    if (nextUserIsSame) {
                      return MessageBubble.next(
                        message: chatMessage['text'],
                        isMe: currentUser!.uid == currentMessageUserId,
                      );
                    } else {
                      return MessageBubble.first(
                        userImage: user.profileImage,
                        username: user.name,
                        message: chatMessage['text'],
                        isMe: currentUser!.uid == currentMessageUserId,
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
    );
  }
}
