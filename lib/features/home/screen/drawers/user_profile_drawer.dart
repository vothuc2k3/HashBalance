import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/setting/setting_screen.dart';
import 'package:hash_balance/features/user_profile/screen/user_profile_screen.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:hash_balance/theme/pallette.dart';

class UserProfileDrawer extends ConsumerStatefulWidget {
  final BuildContext _homeScreenContext;

  const UserProfileDrawer({
    super.key,
    required BuildContext homeScreenContext,
  }) : _homeScreenContext = homeScreenContext;

  @override
  UserProfileDrawerState createState() => UserProfileDrawerState();
}

class UserProfileDrawerState extends ConsumerState<UserProfileDrawer> {
  void navigateToProfileScreen(BuildContext context, String uid) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          uid: uid,
        ),
      ),
    );
  }

  void navigateToSettingScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingScreen(),
      ),
    );
  }

  void _changeUserPrivacy(
    WidgetRef ref,
    bool setting,
    UserModel user,
    BuildContext homeScreenContext,
  ) async {
    final result =
        await ref.read(authControllerProvider.notifier).changeUserPrivacy(
              setting: setting,
              user: user,
            );
    result.fold((l) => showSnackBar(homeScreenContext, l.message),
        (r) => showMaterialBanner(homeScreenContext, r.toString()));
  }

  void showChangePrivacyModal(
    BuildContext homeScreenContext,
    BuildContext drawerContext,
    WidgetRef ref,
  ) {
    final user = ref.watch(userProvider);
    bool userIsRestricted = user!.isRestricted;
    int isLoading = 0;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext bottomSheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 3,
            width: 40,
            color: Colors.grey,
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),
          ListTile(
            leading: isLoading == 1
                ? const CircularProgressIndicator()
                : const Icon(Icons.public),
            title: !userIsRestricted
                ? const Text(
                    'Current: Public',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : const Text('Public'),
            subtitle: const Text('Everybody can send you friend requests'),
            onTap: !userIsRestricted
                ? () {}
                : () {
                    setState(() {
                      isLoading = 1;
                    });
                    Timer(
                      const Duration(seconds: 1),
                      () {
                        Navigator.pop(bottomSheetContext);
                        Scaffold.of(homeScreenContext).closeEndDrawer();
                        _changeUserPrivacy(
                          ref,
                          false,
                          user,
                          widget._homeScreenContext,
                        );
                      },
                    );
                  },
          ),
          ListTile(
            leading: isLoading == 2
                ? const CircularProgressIndicator()
                : const Icon(Icons.privacy_tip),
            title: userIsRestricted
                ? const Text(
                    'Current: Private',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : const Text('Private'),
            subtitle: const Text('Only you can send friend requests to others'),
            onTap: userIsRestricted
                ? () {}
                : () {
                    setState(() {
                      isLoading = 2;
                    });
                    Timer(
                      const Duration(seconds: 1),
                      () {
                        Navigator.pop(bottomSheetContext);
                        Scaffold.of(homeScreenContext).closeEndDrawer();
                        _changeUserPrivacy(
                          ref,
                          true,
                          user,
                          widget._homeScreenContext,
                        );
                      },
                    );
                  },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                Timer(const Duration(milliseconds: 200), () {
                  navigateToProfileScreen(context, user.uid);
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
                        Text(
                          '#${user.name}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
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
                'Profile Management',
                style: TextStyle(
                  color: Pallete.whiteColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: const Icon(Icons.manage_accounts),
              onTap: () {},
            ),
            ListTile(
              title: const Text(
                'Change Privacy Settings',
                style: TextStyle(
                  color: Pallete.whiteColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: const Icon(Icons.privacy_tip),
              onTap: () => showChangePrivacyModal(
                context,
                widget._homeScreenContext,
                ref,
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
              onTap: () => navigateToSettingScreen(),
            ),
          ],
        ),
      ),
    );
  }
}
