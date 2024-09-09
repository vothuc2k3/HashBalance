import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hash_balance/features/friend/controller/friend_controller.dart';

class FriendRequestsScreen extends ConsumerStatefulWidget {
  final String _uid;

  const FriendRequestsScreen({
    super.key,
    required String uid,
  }) : _uid = uid;

  @override
  ConsumerState<FriendRequestsScreen> createState() =>
      _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends ConsumerState<FriendRequestsScreen> {
  void _acceptFriendRequest() {}

  void _deleteFriendRequest() {}

  @override
  Widget build(BuildContext context) {
    final friendRequestsAsync = ref.watch(
      fetchFriendRequestsProvider(widget._uid),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends Requests'),
        backgroundColor: const Color(0xFF0D47A1),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D47A1), // Thay thế màu duy nhất ở đây
        ),
        child: friendRequestsAsync.whenOrNull(
              data: (friendRequests) {
                if (friendRequests.isEmpty) {
                  return Center(
                    child: const Text(
                      'You have no new friend requests',
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
                    // Top row with filters
                    const Divider(color: Colors.white54),
                    // Friend request header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Friend requests',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${friendRequests.length}',
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
                        itemCount: friendRequests.length,
                        itemBuilder: (context, index) {
                          final request = friendRequests[index];
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundImage:
                                  NetworkImage(request.requester.profileImage),
                              backgroundColor: Colors.grey.shade700,
                            ),
                            title: Text(
                              request.requester.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade400,
                                    minimumSize: const Size(80, 36),
                                  ),
                                  child: const Text('Confirm'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    side:
                                        const BorderSide(color: Colors.white70),
                                    minimumSize: const Size(80, 36),
                                  ),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              ],
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
