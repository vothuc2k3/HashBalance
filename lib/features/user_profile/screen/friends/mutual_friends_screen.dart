import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/friend/controller/friend_controller.dart';
import 'package:hash_balance/features/message/screen/private_message_screen.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/features/user_profile/screen/user_profile_screen.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:tuple/tuple.dart';

class MutualFriendsScreen extends ConsumerStatefulWidget {
  final String uid;

  const MutualFriendsScreen({super.key, required this.uid});

  @override
  ConsumerState<MutualFriendsScreen> createState() =>
      _MutualFriendsScreenState();
}

class _MutualFriendsScreenState extends ConsumerState<MutualFriendsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUserUid = ref.read(userProvider)!.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mutual Friends',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: ref.watch(preferredThemeProvider).second,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: ref.watch(preferredThemeProvider).first,
        ),
        child: ref
            .watch(mutualFriendsProvider(Tuple2(widget.uid, currentUserUid)))
            .when(
              data: (mutualFriends) {
                if (mutualFriends.isEmpty) {
                  return const Center(
                    child: Text(
                      'No mutual friends found!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: mutualFriends.length,
                  itemBuilder: (context, index) {
                    final friend = mutualFriends[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Colors.grey[850],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        onTap: () => _navigateToProfile(friend.user),
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundImage: CachedNetworkImageProvider(
                            friend.user.profileImage,
                          ),
                          backgroundColor: Colors.grey[700],
                        ),
                        title: Text(
                          friend.user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          friend.user.bio ?? 'No bio available',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        trailing: friend.isFriend
                            ? ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: () => _sendMessage(friend.user),
                                child: const Text(
                                  'Message',
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            : _buildAddFriendButton(friend.user),
                      ).animate().fadeIn(duration: 500.ms).moveY(
                            begin: 30,
                            end: 0,
                            curve: Curves.easeOutBack,
                          ),
                    );
                  },
                );
              },
              error: (error, stackTrace) => Center(
                child: Text(
                  'Error: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              loading: () => const Center(child: Loading()),
            ),
      ),
    );
  }

  Widget _buildAddFriendButton(UserModel targetUser) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
      label: const Text('Add Friend'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 5,
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .moveY(begin: 30, end: 0, duration: 600.ms, curve: Curves.easeOutBack);
  }

  Widget _buildFriendRequestSent(String requestUid) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      label: const Text('Request Sent'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 5,
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .moveY(begin: 30, end: 0, duration: 600.ms, curve: Curves.easeOutBack);
  }

  void _navigateToProfile(UserModel user) {
    if (user.uid == ref.read(userProvider)!.uid) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const UserProfileScreen(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtherUserProfileScreen(
            targetUid: user.uid,
          ),
        ),
      );
    }
  }

  void _sendMessage(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivateMessageScreen(
          targetUser: user,
        ),
      ),
    );
  }

  void _addFriend(UserModel user) {}
}
