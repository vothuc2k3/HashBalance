import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';

class FollowingWidget extends ConsumerStatefulWidget {
  const FollowingWidget({super.key});

  @override
  ConsumerState<FollowingWidget> createState() => _FollowingWidgetState();
}

class _FollowingWidgetState extends ConsumerState<FollowingWidget> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Following'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ref.watch(followersProvider(currentUser.uid)).when(
              data: (result) {
                return result.fold(
                  (failure) => Center(
                    child: Text(
                      'Error: ${failure.message}',
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                    ),
                  ),
                  (followers) {
                    if (followers.isEmpty) {
                      return const Center(
                        child: Text(
                          'No followers found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: followers.length,
                      itemBuilder: (context, index) {
                        final follower = followers[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 4,
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(follower.profileImage),
                            ),
                            title: Text(
                              follower.name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(follower.name),
                            trailing: IconButton(
                              icon: const Icon(Icons.chat_bubble_outline),
                              onPressed: () {},
                            ),
                            onTap: () {},
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text(
                  'Error: $error',
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                ),
              ),
            ),
      ),
    );
  }
}
