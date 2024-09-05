import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/moderation/screen/mod_tools/edit_community_screen.dart';
import 'package:hash_balance/features/moderation/screen/mod_tools/invite_moderators_screen.dart';
import 'package:hash_balance/features/moderation/screen/mod_tools/pending_post_screen.dart';
import 'package:hash_balance/models/community_model.dart';

class ModToolsScreen extends ConsumerWidget {
  final Community community;
  const ModToolsScreen({
    super.key,
    required this.community,
  });

  void _navigateToInviteModeratorsScreen(BuildContext context) {
    print('Navigating to InviteModeratorsScreen');
    print('Community ID: ${community.id}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InviteModeratorsScreen(
          community: community,
        ),
      ),
    );
  }

  void _navigateToEditCommunityScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCommunityScreen(
          id: community.id,
        ),
      ),
    );
  }

  void _navigateToPendingPostScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PendingPostScreen(
          community: community,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Customizing Your Community',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
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
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Pending Posts'),
              onTap: () => _navigateToPendingPostScreen(context),
            ),
            ListTile(
              leading: const Icon(Icons.add_moderator),
              title: const Text('Invite Moderators'),
              onTap: () => _navigateToInviteModeratorsScreen(context),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Community Visual'),
              onTap: () => _navigateToEditCommunityScreen(context),
            ),
            ListTile(
              leading: const Icon(Icons.edit_document),
              title: const Text('Describe about your Community'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Change Community type'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Users Management'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
