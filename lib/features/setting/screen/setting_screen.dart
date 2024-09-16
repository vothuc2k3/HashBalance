import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/authentication/screen/auth_screen.dart';
import 'package:hash_balance/features/theme/controller/theme_controller.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/theme/pallette.dart';

class SettingScreen extends ConsumerStatefulWidget {
  const SettingScreen({super.key});

  @override
  SettingScreenState createState() {
    return SettingScreenState();
  }
}

class SettingScreenState extends ConsumerState<SettingScreen> {
  bool isTrySigningOut = false;

  void _signOut() async{
    setState(() {
      isTrySigningOut = true;
    });
    final uid = ref.read(userProvider)!.uid;
    Timer(
      const Duration(seconds: 1),
      () {
        ref.read(authControllerProvider.notifier).signOut();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (Route<dynamic> route) => false,
        );
      },
    );
    await ref.read(userControllerProvider.notifier).clearUserDeviceToken(uid);
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
              leading: isTrySigningOut
                  ? const Loading()
                  : Icon(
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
