import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/conbined_models/suspended_user_combined_model.dart';
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
  bool isSearching = false;
  final searchController = TextEditingController();
  static List<SuspendedUserCombinedModel> memberList = [];
  List<SuspendedUserCombinedModel> filteredUsers = [];

  List<SuspendedUserCombinedModel> searchUsers(String query) {
    final fuse = Fuzzy(
      memberList.map((e) => e.user.name).toList(),
      options: FuzzyOptions(
        findAllMatches: true,
        tokenize: true,
        threshold: 0.4,
      ),
    );

    final result = fuse.search(query);

    return result
        .map((r) => memberList.firstWhere((e) => e.user.name == r.item))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final suspendedUsers =
        ref.watch(fetchSuspendedUsersProvider(widget.community.id));
    return Scaffold(
      backgroundColor: ref.watch(preferredThemeProvider).first,
      appBar: AppBar(
        backgroundColor: ref.watch(preferredThemeProvider).second,
        title: isSearching
            ? TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: 'Search users...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (query) {
                  setState(() {
                    filteredUsers = query.isEmpty
                        ? List.from(memberList)
                        : searchUsers(query);
                  });
                },
              )
            :const Text('Suspended Users'),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  searchController.clear();
                  filteredUsers = List.from(memberList);
                }
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: suspendedUsers.when(
          data: (users) {
            memberList = users;
            filteredUsers = isSearching ? filteredUsers : users;
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
