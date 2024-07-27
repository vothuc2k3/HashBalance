import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/community/screen/mod_tools/edit_community_screen.dart';
import 'package:hash_balance/features/community/screen/mod_tools/pending_post_screen.dart';
import 'package:hash_balance/models/community_model.dart';

class ModToolsScreen extends ConsumerWidget {
  final Community community;
  const ModToolsScreen({
    super.key,
    required this.community,
  });

  void navigateToEditCommunityScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCommunityScreen(
          id: community.id,
        ),
      ),
    );
  }

  void navigateToPendingPostScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PendingPostScreen(
          communityId: community.id,
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
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Pending Posts'), 
            onTap: () => navigateToPendingPostScreen(context),
          ),
          ListTile(
            leading: const Icon(Icons.add_moderator),
            title: const Text('Add Moderators'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Community Visual'),
            onTap: () => navigateToEditCommunityScreen(context),
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
    );
  }
}
