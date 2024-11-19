import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hash_balance/features/friend/controller/friend_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:tuple/tuple.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  final String _uid;

  const FriendsScreen({
    super.key,
    required String uid,
  }) : _uid = uid;

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  void _handleUnfriend(String targetUid) async {
    final shouldUnfriend = await _showUnfriendConfirmationDialog();

    if (shouldUnfriend) {
      final result =
          await ref.read(friendControllerProvider.notifier).unfriend(targetUid);
      result.fold(
        (l) => showToast(false, l.message),
        (_) => showToast(true, 'Unfriend successfully'),
      );
    }
  }

  Future<bool> _showUnfriendConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: ref.watch(preferredThemeProvider).first,
              title: const Text('Unfriend'),
              content:
                  const Text('Are you sure you want to unfriend this user?'),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No',
                      style: TextStyle(color: Colors.greenAccent)),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes',
                      style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _navigateToOtherUserProfile(String targetUid) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherUserProfileScreen(targetUid: targetUid),
      ),
    );
  }

  Future<void> _onRefresh() async {
    ref.invalidate(fetchFriendsProvider(widget._uid));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Friends'),
        backgroundColor: ref.watch(preferredThemeProvider).second,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: ref.watch(preferredThemeProvider).first,
        ),
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ref.watch(fetchFriendsProvider(widget._uid)).whenOrNull(
                data: (friends) {
                  if (friends.isEmpty) {
                    return ListView(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(
                              child: const Text(
                                'You have no friends yet',
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
                            ),
                          ],
                        ),
                      ],
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
                                  'Your friends',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${friends.length}',
                                  style: const TextStyle(
                                      fontSize: 18, color: Colors.greenAccent),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: friends.length,
                          itemBuilder: (context, index) {
                            final friend = friends[index];
                            return Card(
                              color: ref.watch(preferredThemeProvider).second,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 3,
                              child: ref
                                  .watch(mutualFriendsCountProvider(
                                      Tuple2(widget._uid, friend.uid)))
                                  .whenOrNull(
                                    data: (mutualFriendsCount) => ListTile(
                                      onTap: () => _navigateToOtherUserProfile(
                                          friend.uid),
                                      leading: CircleAvatar(
                                        radius: 30,
                                        backgroundImage:
                                            CachedNetworkImageProvider(
                                          friend.profileImage,
                                        ),
                                        backgroundColor: Colors.grey.shade700,
                                      ),
                                      title: Text(
                                        friend.name,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        'Mutual friends: $mutualFriendsCount',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () =>
                                            _handleUnfriend(friend.uid),
                                      ),
                                    ).animate().fadeIn(duration: 600.ms).moveY(
                                          begin: 30,
                                          end: 0,
                                          duration: 600.ms,
                                          curve: Curves.easeOutBack,
                                        ),
                                  ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ) ??
              const Loading().animate(),
        ),
      ),
    );
  }
}
