import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/friend/controller/friend_controller.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/user_model.dart';

class InviteModeratorsScreen extends ConsumerStatefulWidget {
  final Community _community;

  const InviteModeratorsScreen({
    super.key,
    required Community community,
  }) : _community = community;

  @override
  ConsumerState<InviteModeratorsScreen> createState() =>
      _InviteModeratorsScreenState();
}

class _InviteModeratorsScreenState
    extends ConsumerState<InviteModeratorsScreen> {
  late Future<List<UserModel>> _friends;
  late UserModel _currentUser;

  void _sendInvite(UserModel friend) async {
    final result = await ref
        .read(moderationControllerProvider.notifier)
        .inviteAsModerator(friend.uid, widget._community);
    result.fold((l) => showToast(false, l.message), (r) {
      showToast(true, 'Invite sent to ${friend.name}');
      
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentUser = ref.read(userProvider)!;
    _friends = ref
        .read(friendControllerProvider.notifier)
        .fetchFriendsByUser(_currentUser.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Moderators'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF000000),
              Color(0xFF0D47A1),
              Color(0xFF1976D2),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<UserModel>>(
                future: _friends,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Loading',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Loading(),
                      ].animate().fadeIn(duration: 600.ms).moveY(
                            begin: 30,
                            end: 0,
                            duration: 600.ms,
                            curve: Curves.easeOutBack,
                          ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No friends found'))
                        .animate()
                        .fadeIn(duration: 800.ms);
                  } else {
                    final friends = snapshot.data!;
                    return ListView.builder(
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend = friends[index];

                        return ExpansionTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                CachedNetworkImageProvider(friend.profileImage),
                          ),
                          title: Text(friend.name),
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
                                    onPressed: () => _sendInvite(friend),
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
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
