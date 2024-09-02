import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/screen/community_conversation_screen.dart';
import 'package:hash_balance/features/friend/controller/friend_controller.dart';
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
  List<bool> _checked = [];

  void _sendInvites() {
    Navigator.of(context).pop();
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
              return const Center(child: Text('No friends found'));
            } else {
              final friends = snapshot.data!;
              _checked = List<bool>.filled(friends.length, false);
              return ListView.builder(
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  return CheckboxListTile(
                    title: Text(friends[index].name),
                    value: _checked[index],
                    onChanged: (bool? value) {
                      setState(() {
                        _checked[index] = value!;
                      });
                    },
                  );
                },
              );
            }
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _sendInvites,
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}
