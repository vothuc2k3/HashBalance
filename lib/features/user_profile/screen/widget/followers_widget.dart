import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/widgets/user_card.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/features/user_profile/screen/user_profile_screen.dart';

class FollowersWidget extends ConsumerStatefulWidget {
  const FollowersWidget({super.key});

  @override
  ConsumerState<FollowersWidget> createState() => _FollowersWidgetState();
}

class _FollowersWidgetState extends ConsumerState<FollowersWidget> {
  Future<void> _onRefresh() async {
    final currentUser = ref.read(userProvider)!;
    ref.invalidate(followersProvider(currentUser.uid));
  }

  _navigateToUserProfile(String uid, String currentUid) {
    if (uid == currentUid) {
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
            targetUid: uid,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider)!;

    return Scaffold(
      body: Container(
        color: ref.watch(preferredThemeProvider).first,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: ref.watch(followersProvider(currentUser.uid)).when(
                  data: (result) {
                    return result.fold(
                      (failure) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.8,
                          child: Center(
                            child: Text(
                              'Error: ${failure.message}',
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      (followers) {
                        if (followers.isEmpty) {
                          return SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.8,
                              child: const Center(
                                child: Text(
                                  'You have no followers yet',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey),
                                ),
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: followers.length,
                          itemBuilder: (context, index) {
                            final follower = followers[index];
                            return UserCard(
                              user: follower,
                              theme: ref.watch(preferredThemeProvider).second,
                              onTap: () => _navigateToUserProfile(
                                follower.uid,
                                currentUser.uid,
                              ),
                              isAdmin: false,
                            );
                          },
                        );
                      },
                    );
                  },
                  loading: () => SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.8,
                      child: const Center(
                        child: Loading(),
                      ),
                    ),
                  ),
                  error: (error, stackTrace) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.8,
                      child: Center(
                        child: Text(
                          'Error: ${error.toString()}',
                          style:
                              const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
