import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/message/controller/message_controller.dart';
import 'package:hash_balance/features/message/screen/message_screen.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/models/message_model.dart';

class MessageListScreen extends ConsumerStatefulWidget {
  const MessageListScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MessageListScreenState();
}

class _MessageListScreenState extends ConsumerState<MessageListScreen> {
  void messageUser(String targetUid) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageScreen(
          targetuid: targetUid,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(getCurrentUserConversationProvider);
    final currentUser = ref.watch(userProvider);
    return Scaffold(
      body: conversations.when(
        data: (data) {
          if (data == null || data.isEmpty) {
            return const Center(
              child: Text(
                'There\'s no conversations...',
                style: TextStyle(color: Colors.white),
              ),
            );
          } else {
            Message? lastMessage;
            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final conversation = data[index];
                final messages = ref.watch(
                    getLastMessageByConversationProvider(conversation.id));
                messages.when(
                  data: (data) {
                    lastMessage = data;
                  },
                  error: (error, stackTrace) => ErrorText(
                    error: error.toString(),
                  ),
                  loading: () => const Loading(),
                );

                final otherUser = ref.watch(
                  getUserByUidProvider(
                    conversation.participantUids
                        .firstWhere((uid) => uid != currentUser!.uid),
                  ),
                );
                return Card(
                  color: Colors.black,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: otherUser.when(
                      data: (user) {
                        return CircleAvatar(
                          backgroundImage:
                              CachedNetworkImageProvider(user.profileImage),
                          radius: 30,
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stackTrace) =>
                          const Icon(Icons.error, color: Colors.red),
                    ),
                    title: otherUser.when(
                      data: (user) {
                        return Text(
                          user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                      error: (error, stackTrace) =>
                          ErrorText(error: error.toString()),
                      loading: () => const Loading(),
                    ),
                    subtitle: lastMessage != null
                        ? Text(
                            lastMessage!.uid == currentUser!.uid
                                ? 'You: ${lastMessage!.text}'
                                : lastMessage!.text,
                            style: const TextStyle(color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : const Text(
                            'No messages yet',
                            style: TextStyle(color: Colors.white70),
                          ),
                    trailing: lastMessage != null
                        ? Text(
                            formatTime(lastMessage!.createdAt),
                            style: const TextStyle(color: Colors.white70),
                          )
                        : null,
                    onTap: () {
                      otherUser.when(
                        data: (user) {
                          messageUser(user.uid);
                        },
                        error: (error, stackTrace) =>
                            ErrorText(error: error.toString()),
                        loading: () => const Loading(),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
        error: (error, stackTrace) => ErrorText(error: error.toString()),
        loading: () => const Loading(),
      ),
    );
  }
}
