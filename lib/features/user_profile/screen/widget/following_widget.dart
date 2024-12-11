import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/widgets/user_card.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/features/user_profile/screen/user_profile_screen.dart';

class FollowingWidget extends ConsumerStatefulWidget {
  const FollowingWidget({super.key});

  @override
  ConsumerState<FollowingWidget> createState() => _FollowingWidgetState();
}

class _FollowingWidgetState extends ConsumerState<FollowingWidget> {
  Future<void> _onRefresh() async {
    final currentUser = ref.read(userProvider)!;
    ref.invalidate(followingProvider(currentUser.uid));
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
          child: ref.watch(followingProvider(currentUser.uid)).when(
                data: (result) {
                  return result.fold(
                    (failure) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Center(
                        child: Text(
                          'Error: ${failure.message}',
                          style:
                              const TextStyle(fontSize: 18, color: Colors.grey),
                        ).animate().fadeIn(duration: 600.ms).moveY(
                              begin: 30,
                              end: 0,
                              duration: 600.ms,
                              curve: Curves.easeOutBack,
                            ),
                      ),
                    ),
                    (following) {
                      if (following.isEmpty) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Center(
                            child: const Text(
                              'You are not following anyone yet',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ).animate().fadeIn(duration: 600.ms).moveY(
                                  begin: 30,
                                  end: 0,
                                  duration: 600.ms,
                                  curve: Curves.easeOutBack,
                                ),
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: ListView.builder(
                          itemCount: following.length,
                          itemBuilder: (context, index) {
                            final followee = following[index];
                            return UserCard(
                              user: followee,
                              theme: ref.watch(preferredThemeProvider).second,
                              onTap: () => _navigateToUserProfile(
                                followee.uid,
                                currentUser.uid,
                              ),
                              isAdmin: false,
                            );
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => Center(
                  child: Center(
                    child: const Loading()
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .moveY(
                          begin: 30,
                          end: 0,
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        ),
                  ),
                ),
                error: (error, stackTrace) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Center(
                    child: Text(
                      'Error: ${error.toString()}',
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ).animate().fadeIn(duration: 600.ms).moveY(
                          begin: 30,
                          end: 0,
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        ),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}
