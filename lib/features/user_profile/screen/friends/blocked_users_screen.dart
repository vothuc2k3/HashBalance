import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/friend/controller/friend_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/models/user_model.dart';

class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({
    super.key,
  });

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  void _navigateToOtherUserProfile(String uid) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => OtherUserProfileScreen(
              targetUid: uid,
            )));
  }

  void _handleUnblockUser(UserModel blockedUser) async {
    final currentUser = ref.read(userProvider)!;
    bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ref.watch(preferredThemeProvider).first,
          title: const Text(
            'Unblock User',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          content:
              Text('Are you sure you want to unblock ${blockedUser.name}?'),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.greenAccent),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text(
                'Unblock',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      final result = await ref
          .read(userControllerProvider.notifier)
          .unblockUser(currentUid: currentUser.uid, blockUid: blockedUser.uid);
      result.fold(
        (l) => showToast(false, l.message),
        (r) => showToast(true, 'User unblocked!'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
        backgroundColor: ref.watch(preferredThemeProvider).second,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: ref.watch(preferredThemeProvider).first,
        ),
        child: ref.watch(blockedUsersProvider).whenOrNull(
              data: (blockedModels) {
                if (blockedModels == null || blockedModels.isEmpty) {
                  return Center(
                    child: const Text(
                      'You have not block anyone...',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ).animate().fadeIn(duration: 600.ms).moveY(
                        begin: 30,
                        end: 0,
                        duration: 600.ms,
                        curve: Curves.easeOutBack),
                  );
                }
                return Column(
                  children: [
                    const Divider(color: Colors.white54),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Blocked Users',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${blockedModels.length}',
                                style: const TextStyle(
                                    fontSize: 18, color: Colors.redAccent),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: blockedModels.length,
                        itemBuilder: (context, index) {
                          final blockedUser = blockedModels[index].user;
                          return ListTile(
                            leading: InkWell(
                              onTap: () =>
                                  _navigateToOtherUserProfile(blockedUser.uid),
                              child: CircleAvatar(
                                radius: 25,
                                backgroundImage: CachedNetworkImageProvider(
                                  blockedUser.profileImage,
                                ),
                                backgroundColor: Colors.grey.shade700,
                              ),
                            ),
                            title: Text(
                              blockedUser.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: _buildBlockedStatus(blockedUser),
                          );
                        },
                      ),
                    ),
                  ],
                )..animate().fadeIn(duration: 600.ms).moveY(
                    begin: 30,
                    end: 0,
                    duration: 600.ms,
                    curve: Curves.easeOutBack);
              },
            ) ??
            const Loading().animate(),
      ),
    );
  }

  Widget _buildBlockedStatus(UserModel user) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: () => _handleUnblockUser(user),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade400,
            minimumSize: const Size(80, 36),
          ),
          child: const Text('Unblock'),
        ),
      ],
    );
  }
}
