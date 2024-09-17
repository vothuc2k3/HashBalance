import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hash_balance/features/friend/controller/friend_controller.dart';
import 'package:hash_balance/features/theme/controller/theme_controller.dart';
import 'package:hash_balance/models/user_model.dart';

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
  void _removeFriend(UserModel targetUser) async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Friends'),
        backgroundColor: ref.watch(preferredThemeProvider),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: ref.watch(preferredThemeProvider),
        ),
        child: ref.watch(fetchFriendsProvider(widget._uid)).whenOrNull(
              data: (friends) {
                if (friends.isEmpty) {
                  return Center(
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
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundImage: CachedNetworkImageProvider(
                                friend.profileImage,
                              ),
                              backgroundColor: Colors.grey.shade700,
                            ),
                            title: Text(
                              friend.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text(
                              'Friend',
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _removeFriend(friend),
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
    );
  }
}
