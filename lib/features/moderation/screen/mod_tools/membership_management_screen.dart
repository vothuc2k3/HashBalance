import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/theme/controller/theme_controller.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/user_model.dart';

class MembershipManagementScreen extends ConsumerStatefulWidget {
  final Community _community;

  const MembershipManagementScreen({
    super.key,
    required Community community,
  }) : _community = community;

  @override
  ConsumerState<MembershipManagementScreen> createState() =>
      _MembershipManagementScreenState();
}

class _MembershipManagementScreenState
    extends ConsumerState<MembershipManagementScreen> {
  void _sendInvite(UserModel friend) async {
    final result = await ref
        .read(moderationControllerProvider.notifier)
        .inviteAsModerator(friend.uid, widget._community);
    result.fold(
      (l) => showToast(false, l.message),
      (r) {
        showToast(true, 'Invite sent to ${friend.name}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership Management'),
        backgroundColor: ref.watch(preferredThemeProvider),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: ref.watch(preferredThemeProvider),
        ),
        child: Column(
          children: [
            Expanded(
              child: ref
                  .watch(fetchInitialCommunityMembersProvider(
                      widget._community.id))
                  .when(
                    data: (members) {
                      return ListView.builder(
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final member = members[index];

                          return ExpansionTile(
                            leading: CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(
                                  member.profileImage),
                            ),
                            title: Text(
                              member.uid == ref.read(userProvider)!.uid
                                  ? '${member.name} (You)'
                                  : member.name,
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _sendInvite(member),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.teal,
                                      ),
                                      child: const Text('Send Invite'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    error: (error, stack) => Center(
                      child: Text(error.toString()).animate().shimmer(
                        colors: [Colors.grey, Colors.white],
                      ),
                    ),
                    loading: () => const Center(
                      child: Loading(),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
