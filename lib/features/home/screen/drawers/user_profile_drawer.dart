import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/badge/screen/badges_screen.dart';
import 'package:hash_balance/features/network/controller/network_controller.dart';
import 'package:hash_balance/features/setting/screen/setting_screen.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/screen/activity_log_screen.dart';
import 'package:hash_balance/features/user_profile/screen/friends/friends_screen.dart';
import 'package:hash_balance/features/user_profile/screen/user_followers_screen.dart';
import 'package:hash_balance/features/user_profile/screen/user_profile_screen.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:hash_balance/theme/pallette.dart';
import 'package:mdi/mdi.dart';

class UserProfileDrawer extends ConsumerStatefulWidget {
  const UserProfileDrawer({
    super.key,
  });

  @override
  ConsumerState<UserProfileDrawer> createState() => UserProfileDrawerState();
}

class UserProfileDrawerState extends ConsumerState<UserProfileDrawer> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final connectivityState = ref.watch(connectivityProvider);
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          color: ref.watch(preferredThemeProvider).first,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  Timer(const Duration(milliseconds: 200), () {
                    _navigateToProfileScreen(user);
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage:
                            CachedNetworkImageProvider(user!.profileImage),
                        radius: 50,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            constraints: const BoxConstraints(maxWidth: 150),
                            child: Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            constraints: const BoxConstraints(maxWidth: 150),
                            child: Text(
                              user.email,
                              style: const TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                title: const Text(
                  'My Friends',
                  style: TextStyle(
                    color: Pallete.whiteColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                leading: const Icon(Icons.group),
                onTap: () => _navigateToFriendsScreen(),
              ),
              ListTile(
                title: const Text(
                  'Followers',
                  style: TextStyle(
                    color: Pallete.whiteColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                leading: const Icon(Icons.person_add),
                onTap: () => _navigateToFollowersScreen(),
              ),
              ListTile(
                title: const Text(
                  'Badges',
                  style: TextStyle(
                    color: Pallete.whiteColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                leading: const Icon(Mdi.medal),
                onTap: () => _navigateToBadgesScreen(),
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long),
                onTap: () => _navigateToActivityLogScreen(),
                title: const Text(
                  'Activity Logs',
                  style: TextStyle(
                    color: Pallete.whiteColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.wifi),
                title: connectivityState.when(
                  data: (isConnected) {
                    return Text(
                      isConnected ? 'Connected' : 'No Internet Connection...',
                      style: const TextStyle(
                        color: Pallete.whiteColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                  loading: () => const Text(
                    'Checking...',
                    style: TextStyle(
                      color: Pallete.whiteColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  error: (error, stack) => const Text(
                    'Error',
                    style: TextStyle(
                      color: Pallete.whiteColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                trailing: connectivityState.when(
                  data: (isConnected) {
                    return Icon(
                      isConnected
                          ? Icons.signal_wifi_4_bar
                          : Icons.signal_wifi_off,
                      color: isConnected ? Colors.green : Colors.red,
                    );
                  },
                  loading: () => const Icon(
                    Icons.signal_wifi_statusbar_null,
                    color: Colors.grey,
                  ),
                  error: (error, stack) => const Icon(
                    Icons.error,
                    color: Colors.red,
                  ),
                ),
              ),
              Expanded(child: Container()),
              ListTile(
                title: const Text(
                  'Setting',
                  style: TextStyle(
                    color: Pallete.whiteColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                leading: const Icon(Icons.settings),
                onTap: () => _navigateToSettingScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToProfileScreen(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserProfileScreen()),
    );
  }

  void _navigateToFriendsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendsScreen(
          uid: ref.read(userProvider)!.uid,
        ),
      ),
    );
  }

  void _navigateToSettingScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingScreen(),
      ),
    );
  }

  void _navigateToActivityLogScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ActivityLogScreen(),
      ),
    );
  }

  void _navigateToFollowersScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UserFollowersScreen(),
      ),
    );
  }

  void _navigateToBadgesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BadgesScreen(
          isAdmin: false,
        ),
      ),
    );
  }
}
