import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/moderation/screen/mod_tools/invite_moderators_screen.dart';
import 'package:hash_balance/features/moderation/screen/mod_tools/membership_management_screen.dart';
import 'package:hash_balance/features/moderation/screen/mod_tools/pending_post_screen.dart';
import 'package:hash_balance/features/moderation/screen/mod_tools/reports_screen.dart';
import 'package:hash_balance/features/theme/controller/theme_controller.dart';
import 'package:hash_balance/models/community_model.dart';

class ModToolsScreen extends ConsumerWidget {
  final Community community;
  const ModToolsScreen({
    super.key,
    required this.community,
  });

  void _navigateToReportScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportsScreen(community: community),
      ),
    );
  }

  void _navigateToInviteModeratorsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InviteModeratorsScreen(community: community),
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

  void _navigateToMembershipManagementScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MembershipManagementScreen(
          community: community,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: ref.watch(preferredThemeProvider),
        title: const Text(
          'Moderation Tools',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        color: ref.watch(preferredThemeProvider),
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
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Change Community type'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Membership Management'),
              onTap: () => _navigateToMembershipManagementScreen(context),
            ),
            ListTile(
              leading: const Icon(Icons.warning),
              title: const Text('Report'),
              onTap: () => _navigateToReportScreen(context),
            ),
          ],
        ),
      ),
    );
  }
}
