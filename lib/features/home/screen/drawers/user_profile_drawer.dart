import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/theme/pallette.dart';
import 'package:routemaster/routemaster.dart';

class UserProfileDrawer extends ConsumerWidget {
  const UserProfileDrawer({super.key});

  void navigateToSettingScreen(BuildContext context) {
    Routemaster.of(context).push('/setting');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(user!.profileImage),
                    radius: 50,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${user.name}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
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
              leading: const Icon(
                Icons.manage_accounts,
              ),
              onTap: () {},
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
              leading: const Icon(
                Icons.settings,
              ),
              onTap: () => navigateToSettingScreen(context),
            ),
          ],
        ),
      ),
    );
  }
}
