import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/screen/auth_screen.dart';
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

  void signOut() {
    setState(() {
      isTrySigningOut = true;
    });
    Timer(const Duration(seconds: 1), () {
      ref.read(authControllerProvider.notifier).signOut(ref);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Setting',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          ListTile(
            leading: isTrySigningOut
                ? const CircularProgressIndicator()
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
            onTap: () => signOut(),
          ),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Pallete.redColor,
            ),
            title: const Text(
              'Open the test screen',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
