import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/community/screen/community_conversation_screen.dart';
import 'package:hash_balance/features/message/screen/active_conversations_screen.dart';
import 'package:hash_balance/features/message/screen/archived_conversations_screen.dart';
import 'package:hash_balance/features/message/screen/private_message_screen.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/user_model.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToPrivateMessageScreen(UserModel targetUser) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivateMessageScreen(
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
    final screens = [
      ActiveConversationsScreen(
        navigateToPrivateMessageScreen: _navigateToPrivateMessageScreen,
        navigateToCommunityConversationScreen:
            _navigateToCommunityConversationScreen,
      ),
      const ArchivedConversationsScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: ref.watch(preferredThemeProvider).second,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.archive),
            label: 'Archived',
          ),
        ],
      ),
    );
  }
}
