import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/controller/community_controller.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/moderation/screen/mod_tools/archived_posts_screen.dart';
import 'package:hash_balance/features/moderation/screen/mod_tools/invite_moderators_screen.dart';
import 'package:hash_balance/features/moderation/screen/mod_tools/membership_management/membership_management_screen.dart';
import 'package:hash_balance/features/moderation/screen/mod_tools/pending_post_screen.dart';
import 'package:hash_balance/features/moderation/screen/mod_tools/rejected_posts_screen.dart';
import 'package:hash_balance/features/moderation/screen/mod_tools/reports_screen.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ModToolsScreen extends ConsumerStatefulWidget {
  final Community community;
  const ModToolsScreen({
    super.key,
    required this.community,
  });

  @override
  ConsumerState<ModToolsScreen> createState() => _ModToolsScreenState();
}

class _ModToolsScreenState extends ConsumerState<ModToolsScreen> {
  Community get community => widget.community;

  void _changeCommunityType(String type) async {
    final result = await ref
        .read(moderationControllerProvider.notifier)
        .changeCommunityType(communityId: community.id, type: type);
    result.fold((l) => showToast(false, l.message), (r) {
      showToast(true, 'Community type changed successfully');
      Navigator.pop(context);
    });
  }

  void _handleCommunityTypeChange(String type) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ref.watch(preferredThemeProvider).first,
          title: const Text('Confirm Changes'),
          content: Text(
              'Are you sure you want to change the community type to $type?'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(
                  color: Colors.white,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child:
                  const Text('No', style: TextStyle(color: Colors.greenAccent)),
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _changeCommunityType(type);
              },
              child:
                  const Text('Yes', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  void _showCommunityTypeModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ref.watch(preferredThemeProvider).first,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 3,
              width: 40,
              color: Colors.grey,
              margin: const EdgeInsets.symmetric(vertical: 8),
            ),
            const SizedBox(height: 10),
            const Text(
              'Community type',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            ...Constants.communityTypes.map<Widget>(
              (String value) {
                final isSelected = value == community.type;
                return ListTile(
                  leading: Icon(
                    Constants.communityTypeIcons[value],
                    color: isSelected ? Colors.blueAccent : Colors.white,
                  ),
                  title: Text(
                    value,
                    style: TextStyle(
                      color: isSelected ? Colors.blueAccent : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    Constants.communityTypesDescMap[value]!,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.blueAccent,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    _handleCommunityTypeChange(value);
                  },
                );
              },
            ),
          ],
        ).animate().fadeIn();
      },
    );
  }

  void _navigateToArchivedPostsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArchivedPostScreen(community: community),
      ),
    );
  }

  void _navigateToReportScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportsScreen(community: community),
      ),
    );
  }

  void _navigateToInviteModeratorsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InviteModeratorsScreen(community: community),
      ),
    );
  }

  void _navigateToPendingPostScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PendingPostScreen(community: community),
      ),
    );
  }

  void _navigateToRejectedPostScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RejectedPostScreen(community: community),
      ),
    );
  }

  void _navigateToMembershipManagementScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MembershipManagementScreen(
          community: community,
        ),
      ),
    );
  }

  Future<void> _loadIsCreator() async {
    final isCreator = await ref
        .read(communityControllerProvider.notifier)
        .isCommunityCreator(
            communityId: community.id, uid: ref.read(userProvider)!.uid);
    ref.read(isCreatorProvider.notifier).update((state) => isCreator);
  }

  @override
  void initState() {
    super.initState();
    _loadIsCreator();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(moderationControllerProvider);
    final isCreator = ref.watch(isCreatorProvider);
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: ref.watch(preferredThemeProvider).second,
        title: const Text(
          'Moderation Tools',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        color: ref.watch(preferredThemeProvider).first,
        child: Column(
          children: [
            if (isCreator)
              ListTile(
                leading: const Icon(Icons.add_moderator),
                title: const Text('Invite Moderators'),
                onTap: () => _navigateToInviteModeratorsScreen(),
              ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Invite Members'),
              onTap: () {},
            ),
            if (community.type == 'Private' || community.type == 'Restricted')
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Pending Posts'),
                onTap: () => _navigateToPendingPostScreen(),
              ),
            if (community.type == 'Private' || community.type == 'Restricted')
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Rejected Posts'),
                onTap: () => _navigateToRejectedPostScreen(),
              ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archived Posts'),
              onTap: () => _navigateToArchivedPostsScreen(),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Change Community type'),
              onTap: () => isLoading ? null : _showCommunityTypeModal(),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Membership Management'),
              onTap: () => _navigateToMembershipManagementScreen(),
            ),
            ListTile(
              leading: Stack(
                children: [
                  const Icon(Icons.warning),
                  ref
                      .watch(unresolvedReportCountProvider(widget.community.id))
                      .when(
                        data: (data) {
                          if (data == 0) {
                            return const SizedBox.shrink();
                          }
                          return Positioned(
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 12,
                                minHeight: 12,
                              ),
                              child: Text(
                                '$data',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      )
                ],
              ),
              title: const Text('Reports Management'),
              onTap: () => _navigateToReportScreen(),
            ),
          ],
        ),
      ),
    );
  }
}

final isCreatorProvider = StateProvider<bool>((ref) => false);
