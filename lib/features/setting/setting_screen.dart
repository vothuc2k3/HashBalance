import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/theme/pallette.dart';
import 'package:routemaster/routemaster.dart';

class SettingScreen extends ConsumerStatefulWidget {
  const SettingScreen({super.key});

  @override
  SettingScreenState createState() {
    return SettingScreenState();
  }
}

class SettingScreenState extends ConsumerState<SettingScreen> {
  bool isTrySigningOut = false;

  void signOut(BuildContext context, WidgetRef ref) {
    setState(() {
      isTrySigningOut = true;
    });
    Timer(const Duration(seconds: 1), () {
      ref.read(authControllerProvider.notifier).signOut(ref);
      Routemaster.of(context).replace('/');
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
            onTap: () => signOut(context, ref),
          ),
        ],
      ),
    );
  }
}
