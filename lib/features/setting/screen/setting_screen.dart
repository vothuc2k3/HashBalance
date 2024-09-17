import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/theme/controller/theme_controller.dart';
import 'package:hash_balance/theme/pallette.dart';
import 'package:logger/logger.dart';

class SettingScreen extends ConsumerStatefulWidget {
  const SettingScreen({super.key});

  @override
  SettingScreenState createState() {
    return SettingScreenState();
  }
}

class SettingScreenState extends ConsumerState<SettingScreen> {
  void _signOut() async {
    Logger().d('REACHED HERE');

    // Đảm bảo signOut được thực hiện trước
    await ref.watch(authControllerProvider.notifier).signOut(context);
    Logger().d('SIGNED OUT SUCCESSFULLY');
  }

  void _testButton() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ref.watch(preferredThemeProvider),
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
          color: ref.watch(
            preferredThemeProvider,
          ),
        ),
        child: Column(
          children: [
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Pallete.redColor,
              ),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: _signOut,
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
