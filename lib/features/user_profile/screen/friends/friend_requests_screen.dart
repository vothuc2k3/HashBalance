import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hash_balance/features/friend/controller/friend_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/conbined_models/friend_requester_data_model.dart';
import 'package:hash_balance/models/user_model.dart';

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
  List<FriendRequesterDataModel> _friendRequests = [];

  void _acceptFriendRequest(UserModel targetUser) async {
    await ref
        .read(friendControllerProvider.notifier)
        .acceptFriendRequest(targetUser);
  }

  void _deleteFriendRequest(UserModel targetUser) async {
    await ref
        .read(friendControllerProvider.notifier)
        .declineFriendRequest(targetUser);
  }

  Future<void> _refreshFriendRequests() async {
    ref.invalidate(fetchFriendRequestsProvider(widget._uid));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshFriendRequests,
        child: Container(
          decoration: BoxDecoration(
            color: ref.watch(preferredThemeProvider).first,
          ),
          child: ref.watch(fetchFriendRequestsProvider(widget._uid)).when(
                    data: (friendRequests) {
                      _friendRequests = friendRequests;
                      if (_friendRequests.isEmpty) {
                        return ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.4,
                            ),
                            Center(
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
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          const Divider(color: Colors.white54),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
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
                                      '${_friendRequests.length}',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.redAccent),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _friendRequests.length,
                              itemBuilder: (context, index) {
                                final request = _friendRequests[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    radius: 25,
                                    backgroundImage: CachedNetworkImageProvider(
                                      request.requester.profileImage,
                                    ),
                                    backgroundColor: Colors.grey.shade700,
                                  ),
                                  title: Text(
                                    request.requester.name,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: _buildFriendRequestStatus(request),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                    error: (error, stackTrace) {
                      return Center(
                        child: Text(error.toString()),
                      );
                    },
                    loading: () => const Loading().animate(),
                  ) ??
              const Loading().animate(),
        ),
      ),
    );
  }

  Widget _buildFriendRequestStatus(FriendRequesterDataModel request) {
    switch (request.friendRequest.status) {
      case 'pending':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => _acceptFriendRequest(request.requester),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade400,
                minimumSize: const Size(80, 36),
              ),
              child: const Text('Confirm'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _deleteFriendRequest(request.requester),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white70),
                minimumSize: const Size(80, 36),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        );
      case 'accepted':
        return const Text(
          'You two are now friends!',
          style:
              TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
        );
      case 'declined':
        return const Text(
          'Friend request declined',
          style:
              TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
