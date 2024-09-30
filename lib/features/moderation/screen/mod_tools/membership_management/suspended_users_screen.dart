import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SuspendedUsersScreen extends ConsumerStatefulWidget {
  final Community community;

  const SuspendedUsersScreen({
    super.key,
    required this.community,
  });

  @override
  ConsumerState<SuspendedUsersScreen> createState() =>
      _SuspendedUsersScreenState();
}

class _SuspendedUsersScreenState extends ConsumerState<SuspendedUsersScreen> {
  @override
  Widget build(BuildContext context) {
    final suspendedUsers =
        ref.watch(fetchSuspendedUsersProvider(widget.community.id));

    return Scaffold(
      backgroundColor: ref.watch(preferredThemeProvider).first,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: suspendedUsers.when(
          data: (users) {
            if (users.isEmpty) {
              return Center(
                child: const Text(
                  'No suspended users.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ).animate().fadeIn(),
              );
            }
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: ref.watch(preferredThemeProvider).third,
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundImage:
                          CachedNetworkImageProvider(user.user.profileImage),
                    ),
                    title: Text(
                      user.user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Suspended for ${user.suspension.days} days',
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _unsuspendUser(user.user),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                      ),
                      child: const Text('Unsuspend'),
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms);
              },
            );
          },
          error: (error, stackTrace) => Center(
            child: Text(
              'Error: $error',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  void _unsuspendUser(UserModel user) {
    // Logic to unsuspend the user
  }
}
