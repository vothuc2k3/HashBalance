import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/message/controller/message_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/conbined_models/last_message_data_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ArchivedConversationsScreen extends ConsumerStatefulWidget {
  const ArchivedConversationsScreen({super.key});

  @override
  ConsumerState<ArchivedConversationsScreen> createState() =>
      _ArchivedConversationsScreenState();
}

class _ArchivedConversationsScreenState
    extends ConsumerState<ArchivedConversationsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.read(userProvider)!;
    return Container(
      decoration: BoxDecoration(
        color: ref.watch(preferredThemeProvider).first,
      ),
      child: Center(
        child: ref.watch(getArchivedConversationsProvider).when(
              data: (conversations) {
                if (conversations.isEmpty) {
                  return const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.archive,
                        color: Colors.white70,
                        size: 80,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'You have no archived conversations',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ).animate().fadeIn();
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
                          return _buildMessageCard(
                            messageData,
                            currentUser,
                            conversation.type,
                            conversation.id,
                          );
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

  Widget _buildMessageCard(
    LastMessageDataModel messageData,
    UserModel currentUser,
    String conversationType,
    String conversationId,
  ) {
    return Card(
      color: Colors.black,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        children: [
          ListTile(
            onLongPress: () => _showMessageOptions(messageData, conversationId),
            tileColor: ref.watch(preferredThemeProvider).second,
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(
                conversationType == 'Community'
                    ? messageData.community!.profileImage
                    : messageData.targetUser!.profileImage,
              ),
              radius: 30,
            ),
            title: Text(
              conversationType == 'Community'
                  ? messageData.community!.name
                  : messageData.targetUser!.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            subtitle: Text(
              messageData.message.uid == currentUser.uid
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
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
              ),
              child: const Text(
                'Archived',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  void _showMessageOptions(
      LastMessageDataModel messageData, String conversationId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: ref.watch(preferredThemeProvider).second,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.archive),
                title: const Text('Unarchive this conversation'),
                onTap: () {
                  Navigator.pop(context);
                  _handleUnarchive(conversationId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleUnarchive(String conversationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ref.watch(preferredThemeProvider).second,
        title: const Text(
          'Are you sure you want to unarchive this conversation?',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _unarchiveConversation(conversationId);
              Navigator.pop(context);
            },
            child: const Text(
              'Unarchive',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _unarchiveConversation(String conversationId) async {
    final result = await ref
        .read(messageControllerProvider.notifier)
        .unarchiveConversation(conversationId: conversationId);
    result.fold(
        (l) => showToast(false, l.message),
        (r) => showToast(true, 'Conversation unarchived'));
  }
}
