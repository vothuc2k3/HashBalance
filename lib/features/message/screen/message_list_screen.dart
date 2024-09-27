import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/screen/community_conversation_screen.dart';
import 'package:hash_balance/features/message/controller/message_controller.dart';
import 'package:hash_balance/features/message/screen/private_message_screen.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/user_model.dart';

class MessageListScreen extends ConsumerStatefulWidget {
  const MessageListScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MessageListScreenState();
}

class _MessageListScreenState extends ConsumerState<MessageListScreen> {
  void _navigateToPrivateMessageScreen(UserModel targetUser) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageScreen(
          targetUser: targetUser,
        ),
      ),
    );
  }

  void _navigateToCommunityConversationScreen(Community community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityConversationScreen(
          community: community,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(getCurrentUserConversationProvider);
    final currentUser = ref.watch(userProvider);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: ref.watch(preferredThemeProvider).first,
        ),
        child: conversations.when(
          data: (conversations) {
            if (conversations == null || conversations.isEmpty) {
              return Center(
                child: const Text(
                  'You have no conversation going on...',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ).animate().fadeIn(duration: 600.ms).moveY(
                      begin: 30,
                      end: 0,
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                    ),
              );
            } else {
              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  final messages = ref.watch(
                      getLastMessageByConversationProvider(conversation));
                  return messages.when(
                    data: (messageData) {
                      return Card(
                        color: Colors.black,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          tileColor: ref.watch(preferredThemeProvider).second,
                          leading: CircleAvatar(
                            backgroundImage: CachedNetworkImageProvider(
                              messageData.conversation.type == 'Community'
                                  ? messageData.community!.profileImage
                                  : messageData.targetUser!.profileImage,
                            ),
                            radius: 30,
                          ),
                          title: Text(
                            messageData.conversation.type == 'Community'
                                ? messageData.community!.name
                                : messageData.targetUser!.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            messageData.message.uid == currentUser!.uid
                                ? 'You: ${messageData.message.text ?? ''}'
                                : messageData.message.text ?? '',
                            style: const TextStyle(color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            formatTime(messageData.message.createdAt),
                            style: const TextStyle(color: Colors.white70),
                          ),
                          onTap: () {
                            switch (conversation.type) {
                              case 'Private':
                                _navigateToPrivateMessageScreen(
                                  messageData.targetUser!,
                                );
                                break;
                              case 'Community':
                                _navigateToCommunityConversationScreen(
                                  messageData.community!,
                                );
                                break;
                              default:
                                break;
                            }
                          },
                        ),
                      ).animate().fadeIn();
                    },
                    error: (error, stackTrace) => ErrorText(
                      error: error.toString(),
                    ),
                    loading: () => const SizedBox.shrink(),
                  );
                },
              );
            }
          },
          error: (error, stackTrace) => ErrorText(error: error.toString()),
          loading: () => const Loading(),
        ),
      ),
    );
  }
}
