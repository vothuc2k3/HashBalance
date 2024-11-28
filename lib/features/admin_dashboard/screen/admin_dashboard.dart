import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/admin_dashboard/controller/admin_dashboard_controller.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/home/screen/search_screen.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/features/user_profile/screen/user_profile_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({
    super.key,
  });

  @override
  ConsumerState<AdminDashboardScreen> createState() {
    return AdminDashboardScreenState();
  }
}

class AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  _onRefresh() async {
    ref.invalidate(usersCountProvider);
    ref.invalidate(postsCountProvider);
    ref.invalidate(commentsCountProvider);
    ref.invalidate(reportsCountProvider);
    ref.invalidate(trendingHashtagsProvider);
  }

  _onSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchSuggestionsScreen(),
      ),
    );
  }

  _onUserTap(String uid) {
    if (uid.isNotEmpty && uid == ref.read(userProvider)!.uid) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const UserProfileScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtherUserProfileScreen(targetUid: uid),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ref.watch(preferredThemeProvider).first,
      appBar: AppBar(
        backgroundColor: ref.watch(preferredThemeProvider).second,
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            onPressed: () => _onSearch(),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ref.watch(usersCountProvider).when(
                        data: (usersCount) => _buildStatCard(
                          title: "Users",
                          value: usersCount.toString(),
                          icon: Icons.people,
                          color: Colors.blueAccent,
                        ),
                        loading: () => const Loading(),
                        error: (error, stack) => Text(error.toString()),
                      ),
                  ref.watch(postsCountProvider).when(
                        data: (postsCount) => _buildStatCard(
                          title: "Posts",
                          value: postsCount.toString(),
                          icon: Icons.post_add,
                          color: Colors.greenAccent,
                        ),
                        loading: () => const Loading(),
                        error: (error, stack) => Text(error.toString()),
                      ),
                  ref.watch(commentsCountProvider).when(
                        data: (commentsCount) => _buildStatCard(
                          title: "Comments",
                          value: commentsCount.toString(),
                          icon: Icons.comment,
                          color: Colors.orangeAccent,
                        ),
                        loading: () => const Loading(),
                        error: (error, stack) => Text(error.toString()),
                      ),
                  ref.watch(reportsCountProvider).when(
                        data: (reportsCount) => _buildStatCard(
                          title: "Reports",
                          value: reportsCount.toString(),
                          icon: Icons.report,
                          color: Colors.redAccent,
                        ),
                        loading: () => const Loading(),
                        error: (error, stack) => Text(error.toString()),
                      ),
                ],
              ),
              const SizedBox(height: 20),

              // Section: Chart
              const Text(
                "Hashtag Trends",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ref.watch(trendingHashtagsProvider).when(
                      data: (trendingHashtags) =>
                          _buildTrendingHashtags(trendingHashtags),
                      loading: () => const Loading(),
                      error: (error, stack) => Text(error.toString()),
                    ),
              ),
              const SizedBox(height: 20),
              _buildTopActiveUsers(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingHashtags(List<Map<String, dynamic>> trendingHashtags) {
    final hashtags = trendingHashtags;
    return SizedBox(
      height: 100,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: hashtags.map((hashtag) {
            return Container(
              width: 150,
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    hashtag['tag'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${hashtag['count']} Posts",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopActiveUsers() {
    return ref.watch(topActiveUsersProvider).when(
          data: (activeUsers) {
            if (activeUsers.isEmpty) {
              return const Center(
                child: Text("No active users found",
                    style: TextStyle(color: Colors.grey)),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Top Active Users",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeUsers.length,
                  itemBuilder: (context, index) {
                    final user = activeUsers[index];
                    return ListTile(
                      onTap: () => _onUserTap(user['uid'] as String),
                      leading: CircleAvatar(
                        backgroundImage: user['profileImage'].isNotEmpty
                            ? NetworkImage(user['profileImage'])
                            : null,
                        child: user['profileImage'].isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(user['name']),
                      subtitle: Text(
                        "${user['posts']} Posts • ${user['comments']} Comments • ${user['activityPoint']} Activity Points",
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ],
            );
          },
          loading: () => const Center(child: Loading()),
          error: (error, stackTrace) => Center(
            child: Text("Error: $error",
                style: const TextStyle(color: Colors.red)),
          ),
        );
  }
}
