import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/message/controller/message_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/conbined_models/last_message_data_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Chats Screen showing current conversations
class ActiveConversationsScreen extends ConsumerStatefulWidget {
  final Function(UserModel) navigateToPrivateMessageScreen;
  final Function(Community) navigateToCommunityConversationScreen;

  const ActiveConversationsScreen({
    super.key,
    required this.navigateToPrivateMessageScreen,
    required this.navigateToCommunityConversationScreen,
  });

  @override
  ConsumerState<ActiveConversationsScreen> createState() =>
      _ActiveConversationsScreenState();
}

class _ActiveConversationsScreenState
    extends ConsumerState<ActiveConversationsScreen> {

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider);
    return Container(
      decoration: BoxDecoration(
        color: ref.watch(preferredThemeProvider).first,
      ),
      child: ref.watch(getCurrentUserConversationsProvider).when(
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
            return RefreshIndicator(
              onRefresh: () async {},
              child: ListView.builder(
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
                        currentUser!,
                        conversation.type,
                        conversation.id,
                        widget.navigateToPrivateMessageScreen,
                        widget.navigateToCommunityConversationScreen,
                      );
                    },
                    error: (error, stackTrace) => ErrorText(
                      error: error.toString(),
                    ),
                    loading: () => const SizedBox.shrink(),
                  );
                },
              ),
            );
          }
        },
        error: (error, stackTrace) => ErrorText(error: error.toString()),
        loading: () => const Loading(),
      ),
    );
  }

  // Widget to build the message card
  Widget _buildMessageCard(
    LastMessageDataModel messageData,
    UserModel currentUser,
    String conversationType,
    String conversationId,
    Function(UserModel) navigateToPrivate,
    Function(Community) navigateToCommunity,
  ) {
    return Card(
      color: Colors.black,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        onLongPress: () => _showMessageOptions(
          messageData,
          conversationId,
        ),
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
        onTap: () {
          if (conversationType == 'Private') {
            navigateToPrivate(messageData.targetUser!);
          } else {
            navigateToCommunity(messageData.community!);
          }
        },
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
                title: const Text('Archive this conversation'),
                onTap: () {
                  Navigator.pop(context);
                  _handleArchive(conversationId);
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

  void _handleArchive(String conversationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ref.watch(preferredThemeProvider).second,
        title: const Text(
          'Are you sure you want to archive this conversation?',
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
              _archiveConversation(conversationId);
              Navigator.pop(context);
            },
            child: const Text(
              'Archive',
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

  void _archiveConversation(String conversationId) async {
    final result = await ref
        .read(messageControllerProvider.notifier)
        .archiveConversation(conversationId: conversationId);
    result.fold((l) => showToast(false, l.message), (r) {
      showToast(true, 'Conversation archived');
      setState(() {});
    });
  }
}
