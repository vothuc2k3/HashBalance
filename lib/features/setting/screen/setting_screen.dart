// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/screen/auth_screen.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/theme/pallette.dart';

class SettingScreen extends ConsumerStatefulWidget {
  const SettingScreen({super.key});

  @override
  ConsumerState<SettingScreen> createState() {
    return SettingScreenState();
  }
}

class SettingScreenState extends ConsumerState<SettingScreen> {
  void _changeTheme() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose a Theme Color'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.purple,
                ),
                title: const Text('Purple Theme'),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                ),
                title: const Text('Blue Theme'),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _signOut() async {
    await ref.watch(authControllerProvider.notifier).signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (route) => false,
    );
  }

  void _testButton() async {}

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ref.watch(preferredThemeProvider).second,
        title: const Text(
          'Setting',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: ref.watch(preferredThemeProvider).first,
        ),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(
                Icons.color_lens,
                color: Pallete.whiteColor,
              ),
              title: const Text(
                'Change Theme',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: _changeTheme,
            ),
            ListTile(
              leading: isLoading
                  ? const Loading()
                  : const Icon(
                      Icons.logout,
                      color: Pallete.whiteColor,
                    ),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => _signOut(),
            ),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Pallete.redColor,
              ),
              title: const Text(
                'TEST BUTTON',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: _testButton,
            ),
          ],
        ),
      ),
    );
  }
}
